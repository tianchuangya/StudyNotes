import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import St from 'gi://St';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import * as Util from 'resource:///org/gnome/shell/misc/util.js';

const WALLPAPER_LINK = '/home/tianchuangya/.local/share/codex-gnome-liquid-glass/current-desktop-wallpaper';
const WALLPAPER_DIR = '/home/tianchuangya/壁纸';
const POSITION_FILE = '/home/tianchuangya/.config/curtain-wallpaper-position';
const ISLAND_README = '/home/tianchuangya/桌面/unbuntu美化/island-sync/README.md';
const IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp'];
const BALL_SIZE = 58;
const CLIPBOARD_BUTTON_SIZE = 24;
// 与 GNOME dnd 一致：拖拽阈值取自桌面设置（默认 8px），再留一点余量，
// 触摸板点击时的微小抖动不会被误判为拖拽。
const CLICK_JITTER_MARGIN_PX = 4;
const GRAB_SAFETY_TIMEOUT_MS = 3500;

export default class CurtainWallpaperExtension extends Extension {
    enable() {
        this._drag = null;
        this._grab = null;
        this._dragTimeoutId = null;
        this._busy = false;
        this._busySince = 0;
        this._panelWasLight = null;

        this._ball = new St.Button({
            style_class: 'curtain-wallpaper-ball',
            reactive: true,
            can_focus: true,
            track_hover: true,
            accessible_name: '点击切换壁纸，拖动移动，右键打开菜单',
        });
        this._ball.set_pivot_point(0.5, 0.5);
        this._thumbnail = new St.Widget({
            style_class: 'curtain-wallpaper-thumbnail',
            reactive: false,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.CENTER,
        });
        this._ball.set_child(this._thumbnail);
        Main.uiGroup.add_child(this._ball);

        // 与 GNOME dnd 相同：连接 'event' 而不是 'captured-event'——
        // 抓取期间捕获阶段不会发生，只有 'event' 能同时收到球上和球外的指针事件
        this._eventId = this._ball.connect('event', (_actor, event) =>
            this._onEvent(event));

        this._buildMenu();

        this._clipboardButton = new St.Button({
            style_class: 'curtain-wallpaper-clipboard-button',
            reactive: true,
            can_focus: true,
            track_hover: true,
            accessible_name: '打开剪贴板历史',
            child: new St.Icon({
                icon_name: 'edit-paste-symbolic',
                style_class: 'curtain-wallpaper-clipboard-icon',
            }),
        });
        this._clipboardId = this._clipboardButton.connect('clicked', () => this._toggleClipboard());
        Main.uiGroup.add_child(this._clipboardButton);

        this._placeBall();
        this._monitorId = Main.layoutManager.connect('monitors-changed', () => {
            this._placeBall(true);
        });
        this._refreshThumbnail();
        this._updatePanelLuminance();
    }

    _buildMenu() {
        this._menuManager = new PopupMenu.PopupMenuManager(this._ball);
        this._menu = new PopupMenu.PopupMenu(this._ball, 0.5, St.Side.TOP);
        Main.uiGroup.add_child(this._menu.actor);

        this._menu.addMenuItem(this._actionItem('换一张壁纸', () => this._pull()));
        this._menu.addMenuItem(this._actionItem('打开壁纸文件夹', () => {
            Util.spawn(['xdg-open', WALLPAPER_DIR]);
        }));
        this._menu.addMenuItem(this._actionItem('剪贴板历史', () => this._toggleClipboard()));
        this._menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._menu.addMenuItem(this._actionItem('灵动岛设置', () => {
            Util.spawn(['gnome-extensions', 'prefs', 'island-sync@local']);
        }));
        this._menu.addMenuItem(this._actionItem('重载灵动岛扩展', () => {
            Util.spawn(['/usr/bin/bash', '-lc', 'gnome-extensions disable island-sync@local || true; gnome-extensions enable island-sync@local || true']);
        }));
        this._menu.addMenuItem(this._actionItem('打开灵动岛教程', () => {
            Util.spawn(['xdg-open', ISLAND_README]);
        }));
        this._menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._menu.addMenuItem(this._actionItem('重置悬浮球位置', () => {
            try {
                const file = Gio.File.new_for_path(POSITION_FILE);
                file.delete(null);
            } catch (_) { }
            this._placeBall();
            this._savePosition();
        }));
        this._menu.addMenuItem(this._actionItem('锁屏', () => {
            Gio.DBus.session.call(
                'org.gnome.ScreenSaver',
                '/org/gnome/ScreenSaver',
                'org.gnome.ScreenSaver',
                'Lock',
                null, null, Gio.DBusCallFlags.NONE, -1, null, null);
        }));

        this._menuManager.addMenu(this._menu);
        this._menu.actor.hide();
    }

    _actionItem(label, callback) {
        const item = new PopupMenu.PopupMenuItem(label);
        item.connect('activate', () => callback());
        return item;
    }

    _onEvent(event) {
        const type = event.type();

        if (type === Clutter.EventType.BUTTON_PRESS)
            return this._onButtonPress(event);
        if (type === Clutter.EventType.BUTTON_RELEASE)
            return this._onButtonRelease(event);
        if (type === Clutter.EventType.MOTION)
            return this._onMotion(event);

        return Clutter.EVENT_PROPAGATE;
    }

    _onButtonPress(event) {
        const button = event.get_button();

        if (button === 3 && !this._drag) {
            this._menu.toggle();
            return Clutter.EVENT_STOP;
        }
        if (button !== 1)
            return Clutter.EVENT_PROPAGATE;
        if (this._drag)
            return Clutter.EVENT_STOP;
        if (this._busy && Date.now() - this._busySince < 800)
            return Clutter.EVENT_STOP;

        if (this._menu.isOpen)
            this._menu.close();

        const [pointerX, pointerY] = event.get_coords();
        const [ballX, ballY] = this._ball.get_position();
        this._drag = {pointerX, pointerY, ballX, ballY, moved: false};

        // 与 GNOME dnd 的 _grabActor 相同：抓取后即便指针移出球，
        // release 仍会送达球的 'event' 信号，输入状态不会丢失
        this._grab = global.stage.grab(this._ball);
        this._dragTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, GRAB_SAFETY_TIMEOUT_MS, () => {
            this._dragTimeoutId = null;
            if (!this._drag)
                return GLib.SOURCE_REMOVE;
            const moved = this._drag.moved;
            this._teardownGrab();
            if (moved)
                this._savePosition();
            return GLib.SOURCE_REMOVE;
        });
        return Clutter.EVENT_STOP;
    }

    _onMotion(event) {
        if (!this._drag)
            return Clutter.EVENT_PROPAGATE;

        const state = event.get_state();
        if (!(state & Clutter.ModifierType.BUTTON1_MASK)) {
            // release 已被其他输入状态吞掉时的兜底
            const moved = this._drag.moved;
            this._teardownGrab();
            if (moved)
                this._savePosition();
            return Clutter.EVENT_PROPAGATE;
        }
        const [x, y] = event.get_coords();
        const scale = St.ThemeContext.get_for_stage(global.stage).scale_factor;
        const threshold = (St.Settings.get().drag_threshold + CLICK_JITTER_MARGIN_PX) * scale;
        const dx = x - this._drag.pointerX;
        const dy = y - this._drag.pointerY;
        if (Math.abs(dx) > threshold || Math.abs(dy) > threshold)
            this._drag.moved = true;
        if (this._drag.moved) {
            const monitor = Main.layoutManager.primaryMonitor;
            const size = BALL_SIZE;
            const nx = this._drag.ballX + dx;
            const ny = this._drag.ballY + dy;
            this._ball.set_position(
                Math.round(Math.max(monitor.x + 6, Math.min(nx, monitor.x + monitor.width - size - 6))),
                Math.round(Math.max(monitor.y + 30, Math.min(ny, monitor.y + monitor.height - size - 6))));
            this._placeClipboardButton();
        }
        return Clutter.EVENT_STOP;
    }

    _onButtonRelease(event) {
        if (!this._drag)
            return Clutter.EVENT_PROPAGATE;
        if (event.get_button() !== 1)
            return Clutter.EVENT_PROPAGATE;

        const moved = this._drag.moved;
        this._teardownGrab();
        if (moved)
            this._savePosition();
        else
            this._pull();
        return Clutter.EVENT_STOP;
    }

    _teardownGrab() {
        if (this._dragTimeoutId) {
            GLib.Source.remove(this._dragTimeoutId);
            this._dragTimeoutId = null;
        }
        if (this._grab) {
            try { this._grab.dismiss(); } catch (_) { }
            this._grab = null;
        }
        this._drag = null;
    }

    _placeBall(clampOnly = false) {
        const monitor = Main.layoutManager.primaryMonitor;
        if (!monitor || !this._ball)
            return;
        let x = monitor.x + monitor.width - 78;
        let y = monitor.y + 58;
        if (!clampOnly) {
            try {
                const [ok, bytes] = GLib.file_get_contents(POSITION_FILE);
                if (ok) {
                    const values = new TextDecoder().decode(bytes).trim().split(',').map(Number);
                    if (values.length === 2 && values.every(Number.isFinite))
                        [x, y] = values;
                }
            } catch (_) { }
        } else {
            [x, y] = this._ball.get_position();
        }
        x = Math.max(monitor.x + 6, Math.min(x, monitor.x + monitor.width - BALL_SIZE - 6));
        y = Math.max(monitor.y + 30, Math.min(y, monitor.y + monitor.height - BALL_SIZE - 6));
        this._ball.set_position(Math.round(x), Math.round(y));
        this._ball.set_size(BALL_SIZE, BALL_SIZE);
        this._placeClipboardButton();
    }

    // 剪贴板按钮完全位于球的可点击区域之外，避免抢占球的点击
    _placeClipboardButton() {
        if (!this._clipboardButton)
            return;
        const [ballX, ballY] = this._ball.get_position();
        this._clipboardButton.set_position(
            Math.round(ballX + BALL_SIZE + 4),
            Math.round(ballY + BALL_SIZE - CLIPBOARD_BUTTON_SIZE - 4));
        this._clipboardButton.set_size(CLIPBOARD_BUTTON_SIZE, CLIPBOARD_BUTTON_SIZE);
    }

    _savePosition() {
        try {
            const [x, y] = this._ball.get_position();
            GLib.file_set_contents(POSITION_FILE, `${Math.round(x)},${Math.round(y)}\n`);
        } catch (_) { }
    }

    _refreshThumbnail() {
        try {
            const target = GLib.file_read_link(WALLPAPER_LINK);
            const uri = Gio.File.new_for_path(target).get_uri().replaceAll("'", '%27');
            this._thumbnail.set_style(`background-image: url('${uri}');`);
        } catch (_) {
            this._thumbnail.set_style('');
        }
    }

    // 顶栏文字颜色自适应：采样壁纸顶部条带（顶栏所在区域）的平均亮度，
    // 亮壁纸时给 #panel 挂 cw-light-wallpaper 类，CSS 据此把文字换成深色，
    // 避免固定白色文字在浅色壁纸上被"淹没"。参考 liquid-glass-react 的
    // overLight 自适应思路。
    _updatePanelLuminance() {
        import('gi://GdkPixbuf').then(({default: GdkPixbuf}) => {
            try {
                const target = GLib.file_read_link(WALLPAPER_LINK);
                const pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(target, 96, 96);
                const width = pixbuf.get_width();
                const height = pixbuf.get_height();
                const channels = pixbuf.get_n_channels();
                const rowstride = pixbuf.get_rowstride();
                const pixels = pixbuf.get_pixels();
                // 顶栏约占屏幕顶部 3.5%，采样顶部 12 行
                const stripRows = Math.max(4, Math.round(height * 0.12));
                let sum = 0;
                let count = 0;
                for (let y = 0; y < stripRows; y++) {
                    for (let x = 0; x < width; x++) {
                        const offset = y * rowstride + x * channels;
                        const r = pixels[offset];
                        const g = pixels[offset + 1];
                        const b = pixels[offset + 2];
                        sum += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
                        count++;
                    }
                }
                const luma = count > 0 ? sum / count : 0;
                const light = luma > 0.58;
                if (light !== this._panelWasLight) {
                    this._panelWasLight = light;
                    Main.panel.remove_style_class_name('cw-light-wallpaper');
                    Main.panel.remove_style_class_name('cw-dark-wallpaper');
                    Main.panel.add_style_class_name(light ? 'cw-light-wallpaper' : 'cw-dark-wallpaper');
                }
            } catch (error) {
                console.error(`[Curtain Wallpaper] luminance: ${error}`);
            }
        }).catch(error => console.error(`[Curtain Wallpaper] GdkPixbuf unavailable: ${error}`));
    }

    _fileUri(path) {
        return Gio.File.new_for_path(path).get_uri().replaceAll("'", '%27');
    }

    _currentWallpaperPath() {
        try {
            return GLib.file_read_link(WALLPAPER_LINK);
        } catch (_) {
            return null;
        }
    }

    _collectWallpapers(dirPath = WALLPAPER_DIR, results = []) {
        try {
            const dir = Gio.File.new_for_path(dirPath);
            const enumerator = dir.enumerate_children(
                'standard::name,standard::type',
                Gio.FileQueryInfoFlags.NONE,
                null
            );
            let info;
            while ((info = enumerator.next_file(null)) !== null) {
                const childPath = GLib.build_filenamev([dirPath, info.get_name()]);
                if (info.get_file_type() === Gio.FileType.DIRECTORY) {
                    this._collectWallpapers(childPath, results);
                    continue;
                }
                const lower = info.get_name().toLowerCase();
                if (IMAGE_EXTENSIONS.some(ext => lower.endsWith(ext)))
                    results.push(childPath);
            }
            enumerator.close(null);
        } catch (_) { }
        return results;
    }

    _chooseNextWallpaper() {
        const wallpapers = this._collectWallpapers();
        if (wallpapers.length === 0)
            return null;
        const current = this._currentWallpaperPath();
        const candidates = wallpapers.length > 1
            ? wallpapers.filter(path => path !== current)
            : wallpapers;
        return candidates[Math.floor(Math.random() * candidates.length)];
    }

    _applyWallpaper(path) {
        if (!path)
            return false;
        try {
            GLib.mkdir_with_parents(GLib.path_get_dirname(WALLPAPER_LINK), 0o755);
            const link = Gio.File.new_for_path(WALLPAPER_LINK);
            try { link.delete(null); } catch (_) { }
            link.make_symbolic_link(path, null);
            const uri = this._fileUri(path);
            const settings = new Gio.Settings({schema_id: 'org.gnome.desktop.background'});
            settings.set_string('picture-uri', uri);
            settings.set_string('picture-uri-dark', uri);
            settings.set_string('picture-options', 'zoom');
            return true;
        } catch (error) {
            console.error(`[Curtain Wallpaper] ${error}`);
            return false;
        }
    }

    _popFeedback() {
        this._ball.ease({
            scale_x: 1.07,
            scale_y: 1.07,
            duration: 130,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            onComplete: () => {
                this._ball.ease({
                    scale_x: 1,
                    scale_y: 1,
                    duration: 230,
                    mode: Clutter.AnimationMode.EASE_OUT_BACK,
                });
            },
        });
    }

    _pull() {
        if (this._busy && Date.now() - this._busySince < 2000)
            return;
        this._busy = true;
        this._busySince = Date.now();
        try {
            const nextWallpaper = this._chooseNextWallpaper();
            if (this._applyWallpaper(nextWallpaper)) {
                this._refreshThumbnail();
                this._popFeedback();
                this._updatePanelLuminance();
            }
        } catch (error) {
            console.error(`[Curtain Wallpaper] switch failed: ${error}`);
        } finally {
            this._busy = false;
            this._busySince = 0;
        }
    }

    _toggleClipboard() {
        const indicator = Main.panel.statusArea.clipboardIndicator;
        if (!indicator?.menu) {
            Main.notify('剪贴板', 'Clipboard Indicator 当前没有运行');
            return;
        }
        if (indicator.menu.isOpen)
            indicator.menu.close();
        else
            indicator.menu.toggle();
    }

    disable() {
        if (this._monitorId) {
            try { Main.layoutManager.disconnect(this._monitorId); } catch (_) { }
            this._monitorId = null;
        }
        Main.panel?.remove_style_class_name('cw-light-wallpaper');
        Main.panel?.remove_style_class_name('cw-dark-wallpaper');
        this._teardownGrab();
        if (this._ball) {
            if (this._eventId)
                try { this._ball.disconnect(this._eventId); } catch (_) { }
            this._ball.destroy();
            this._ball = null;
            this._thumbnail = null;
        }
        if (this._menu) {
            this._menu.destroy();
            this._menu = null;
        }
        this._menuManager = null;
        if (this._clipboardButton) {
            if (this._clipboardId)
                try { this._clipboardButton.disconnect(this._clipboardId); } catch (_) { }
            this._clipboardButton.destroy();
            this._clipboardButton = null;
        }
        this._busy = false;
        this._busySince = 0;
    }
}
