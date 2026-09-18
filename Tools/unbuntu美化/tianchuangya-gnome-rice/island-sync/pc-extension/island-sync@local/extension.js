import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Pango from 'gi://Pango';
import Soup from 'gi://Soup';
import St from 'gi://St';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import * as Util from 'resource:///org/gnome/shell/misc/util.js';

const APP_ICONS = {
    wechat: 'chat-message-new-symbolic',
    qq: 'user-available-symbolic',
};
const POSITION_FILE = `${GLib.get_user_config_dir()}/island-sync-position`;

function appIconName(app) {
    return APP_ICONS[app] ?? 'phone-symbolic';
}

// ---------------------------------------------------------------------------
// 灵动岛：顶部居中的药丸 + 点击展开的玻璃卡片
// ---------------------------------------------------------------------------
const Island = GObject.registerClass(
class Island extends St.Widget {
    _init(durationSeconds) {
        super._init({
            style_class: 'island-container',
            reactive: false,
            x_align: Clutter.ActorAlign.CENTER,
            layout_manager: new Clutter.BinLayout(),
        });
        this._duration = durationSeconds;
        this._hideTimeoutId = null;
        this._repositionId = null;
        this._drag = null;
        this._dragSignalId = 0;
        this._manualPosition = this._loadPosition();

        this._pill = new St.Button({
            style_class: 'island-pill',
            reactive: true,
            track_hover: true,
            can_focus: true,
            visible: false,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.START,
        });
        this._pillContent = new St.BoxLayout({
            style_class: 'island-pill-content',
            x_align: Clutter.ActorAlign.CENTER,
        });
        this._pill.set_child(this._pillContent);
        this._pill.connect('button-press-event', (_actor, event) => {
            this._startDrag(event);
            return Clutter.EVENT_STOP;
        });
        this._pill.connect('button-release-event', (_actor, event) => {
            if (event.get_button() !== 1)
                return Clutter.EVENT_PROPAGATE;
            return this._finishPointerInteraction(() => this.expand())
                ? Clutter.EVENT_STOP
                : Clutter.EVENT_PROPAGATE;
        });
        this.add_child(this._pill);

        this._backdrop = new St.Button({
            style_class: 'island-backdrop',
            reactive: true,
            visible: false,
            x_align: Clutter.ActorAlign.FILL,
            y_align: Clutter.ActorAlign.FILL,
        });
        this._backdrop.connect('clicked', () => this.collapse());
        this.add_child(this._backdrop);

        this._card = new St.BoxLayout({
            style_class: 'island-card',
            vertical: true,
            reactive: true,
            visible: false,
            x_align: Clutter.ActorAlign.CENTER,
            y_align: Clutter.ActorAlign.START,
        });
        this.add_child(this._card);

        // 居中：跟随自身分配宽度
        this._repositionId = Main.layoutManager.connect('monitors-changed', () => this.syncGeometry());
        this.syncGeometry();
    }

    syncGeometry() {
        const monitor = Main.layoutManager.primaryMonitor;
        if (!monitor)
            return;
        const width = Math.min(this._cardWidth(monitor), monitor.width - 24);
        const height = Math.min(Math.round(monitor.height * 0.54), Math.max(360, Math.round(monitor.height * 0.40)));
        this.set_size(width, height);
        let x = Math.round(monitor.x + (monitor.width - width) / 2);
        let y = Math.round(monitor.y + 34);
        if (this._manualPosition) {
            x = this._manualPosition.x;
            y = this._manualPosition.y;
        }
        this.set_position(...this._clampPosition(x, y, width, height));
        this._pill.set_width(this._pillWidth(monitor));
        this._card.set_width(width);
    }

    _pillWidth(monitor = Main.layoutManager.primaryMonitor) {
        return Math.round(Math.min(monitor.width * 0.32, Math.max(monitor.width * 0.16, 360)));
    }

    _cardWidth(monitor = Main.layoutManager.primaryMonitor) {
        return Math.round(Math.min(monitor.width * 0.42, Math.max(monitor.width * 0.30, 560)));
    }

    _clampPosition(x, y, width = this.width, height = this.height) {
        const monitor = Main.layoutManager.primaryMonitor;
        if (!monitor)
            return [x, y];
        return [
            Math.round(Math.max(monitor.x + 8, Math.min(x, monitor.x + monitor.width - width - 8))),
            Math.round(Math.max(monitor.y + 30, Math.min(y, monitor.y + monitor.height - height - 8))),
        ];
    }

    _clearPillContent() {
        this._pillContent.destroy_all_children();
    }

    showNotification(notif, onOpenApp) {
        console.log(`[Island Sync] show notification id=${notif.id ?? ''} app=${notif.app ?? ''}`);
        this._onOpenApp = onOpenApp;
        this._current = notif;

        this._clearPillContent();
        this._pillContent.add_child(new St.Icon({
            icon_name: appIconName(notif.app),
            style_class: 'island-pill-icon',
        }));
        this._pillContent.add_child(new St.Label({
            text: notif.title || notif.appLabel || notif.app || '消息',
            style_class: 'island-pill-title',
        }));
        const text = (notif.text || '').replace(/\s+/g, ' ').trim();
        this._pillContent.add_child(new St.Label({
            text: text.slice(0, 42) + (text.length > 42 ? '…' : ''),
            style_class: 'island-pill-text',
        }));

        const canOpenApp = Boolean(onOpenApp);
        this._buildCard(notif, canOpenApp);
        this.syncGeometry();
        this._pill.visible = true;
        this._pill.set_pivot_point(0.5, 0.0);
        this._pill.opacity = 0;
        this._pill.scale_x = 0.55;
        this._pill.scale_y = 0.55;
        this._pill.ease({
            opacity: 255,
            scale_x: 1,
            scale_y: 1,
            duration: 420,
            mode: Clutter.AnimationMode.EASE_OUT_BACK,
        });
        this._scheduleHide();
    }

    _buildCard(notif, canOpenApp) {
        this._card.destroy_all_children();

        const header = new St.BoxLayout({
            style_class: 'island-card-header',
            reactive: true,
        });
        header.connect('button-press-event', (_actor, event) => {
            this._startDrag(event);
            return Clutter.EVENT_STOP;
        });
        header.connect('button-release-event', (_actor, event) => {
            if (event.get_button() !== 1)
                return Clutter.EVENT_PROPAGATE;
            return this._finishPointerInteraction()
                ? Clutter.EVENT_STOP
                : Clutter.EVENT_PROPAGATE;
        });
        header.add_child(new St.Icon({
            icon_name: appIconName(notif.app),
            style_class: 'island-card-icon',
        }));
        header.add_child(new St.Label({
            text: `${notif.title || notif.appLabel || notif.app || '消息'}`,
            style_class: 'island-card-title',
            x_expand: true,
        }));
        const dragHint = new St.Label({
            text: '拖动',
            style_class: 'island-card-drag-hint',
        });
        header.add_child(dragHint);
        this._card.add_child(header);

        const body = new St.Label({
            text: notif.text || '',
            style_class: 'island-card-body',
            x_expand: true,
        });
        const monitor = Main.layoutManager.primaryMonitor;
        if (monitor)
            body.set_style(`max-height: ${Math.round(Math.min(260, Math.max(150, monitor.height * 0.16)))}px;`);
        body.clutter_text.line_wrap = true;
        body.clutter_text.line_wrap_mode = Pango.WrapMode.WORD_CHAR;
        body.clutter_text.ellipsize = Pango.EllipsizeMode.END;
        this._card.add_child(body);

        const buttons = new St.BoxLayout({
            style_class: 'island-card-buttons',
            x_align: Clutter.ActorAlign.END,
        });

        if (canOpenApp) {
            const openButton = new St.Button({
                label: `打开${this._appLabel(notif.app)}`,
                style_class: 'island-card-button island-card-button-primary',
                x_expand: true,
            });
            openButton.connect('clicked', () => {
                this.collapse();
                this._onOpenApp?.(notif.app);
            });
            buttons.add_child(openButton);
        }

        if (notif.text) {
            const copyButton = new St.Button({
                label: '复制内容',
                style_class: 'island-card-button',
                x_expand: true,
            });
            copyButton.connect('clicked', () => {
                const clipboard = St.Clipboard.get_default();
                clipboard.set_text(St.ClipboardType.CLIPBOARD, notif.text);
                this.collapse();
            });
            buttons.add_child(copyButton);
        }

        const closeButton = new St.Button({
            label: '关闭',
            style_class: 'island-card-button',
            x_expand: true,
        });
        closeButton.connect('clicked', () => this.collapse());
        buttons.add_child(closeButton);

        this._card.add_child(buttons);

        // 作者署名：让每一个看到灵动岛的人都知道这是谁的作品
        const footer = new St.Label({
            text: '由 是天创呀 制作 © 2026',
            style_class: 'island-card-footer',
            x_align: Clutter.ActorAlign.END,
        });
        this._card.add_child(footer);
    }

    _appLabel(app) {
        const labels = {wechat: '微信', qq: 'QQ'};
        return labels[app] || '应用';
    }

    expand() {
        this._cancelHide();
        this._backdrop.visible = true;
        this._card.visible = true;
        this.syncGeometry();
        this._card.set_pivot_point(0.5, 0.0);
        this._card.opacity = 0;
        this._card.scale_x = 0.8;
        this._card.scale_y = 0.8;
        this._card.ease({
            opacity: 255,
            scale_x: 1,
            scale_y: 1,
            duration: 260,
            mode: Clutter.AnimationMode.EASE_OUT_BACK,
        });
        this._pill.opacity = 0;
        this._pill.visible = false;
    }

    _startDrag(event) {
        if (event.get_button() !== 1)
            return;
        this._stopDrag();
        const [pointerX, pointerY] = event.get_coords();
        const [actorX, actorY] = this.get_position();
        this._drag = {pointerX, pointerY, actorX, actorY, moved: false};
        this._dragSignalId = global.stage.connect('captured-event', (_stage, dragEvent) => {
            const type = dragEvent.type();
            if (type === Clutter.EventType.MOTION) {
                if (!this._drag)
                    return Clutter.EVENT_PROPAGATE;
                const [x, y] = dragEvent.get_coords();
                const dx = x - this._drag.pointerX;
                const dy = y - this._drag.pointerY;
                if (Math.hypot(dx, dy) > 6)
                    this._drag.moved = true;
                this.set_position(...this._clampPosition(this._drag.actorX + dx, this._drag.actorY + dy));
                return Clutter.EVENT_STOP;
            }
            if (type === Clutter.EventType.BUTTON_RELEASE)
                return this._finishPointerInteraction() ? Clutter.EVENT_STOP : Clutter.EVENT_PROPAGATE;
            return Clutter.EVENT_PROPAGATE;
        });
    }

    _finishPointerInteraction(onClick = null) {
        if (!this._drag)
            return false;
        const moved = this._drag.moved;
        this._stopDrag();
        if (moved) {
            this._savePosition();
        } else {
            onClick?.();
        }
        return true;
    }

    _stopDrag() {
        if (this._dragSignalId) {
            try { global.stage.disconnect(this._dragSignalId); } catch (_) { }
            this._dragSignalId = 0;
        }
        this._drag = null;
    }

    _loadPosition() {
        try {
            const [ok, bytes] = GLib.file_get_contents(POSITION_FILE);
            if (!ok)
                return null;
            const values = new TextDecoder().decode(bytes).trim().split(',').map(Number);
            if (values.length === 2 && values.every(Number.isFinite))
                return {x: values[0], y: values[1]};
        } catch (_) { }
        return null;
    }

    _savePosition() {
        try {
            const [x, y] = this.get_position();
            GLib.mkdir_with_parents(GLib.path_get_dirname(POSITION_FILE), 0o755);
            GLib.file_set_contents(POSITION_FILE, `${Math.round(x)},${Math.round(y)}\n`);
            this._manualPosition = {x: Math.round(x), y: Math.round(y)};
        } catch (_) { }
    }

    collapse() {
        this._card.ease({
            opacity: 0,
            scale_x: 0.85,
            scale_y: 0.85,
            duration: 160,
            mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            onComplete: () => {
                this._card.visible = false;
                this._backdrop.visible = false;
            },
        });
    }

    _scheduleHide() {
        this._cancelHide();
        this._hideTimeoutId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT, Math.max(2, this._duration), () => {
                this._hideTimeoutId = null;
                this._pill.ease({
                    opacity: 0,
                    scale_x: 0.6,
                    scale_y: 0.6,
                    duration: 220,
                    mode: Clutter.AnimationMode.EASE_OUT_QUAD,
                    onComplete: () => {
                        this._pill.visible = false;
                        this._pill.scale_x = 1;
                        this._pill.scale_y = 1;
                        this._pill.opacity = 255;
                    },
                });
                return GLib.SOURCE_REMOVE;
            });
    }

    _cancelHide() {
        if (this._hideTimeoutId) {
            GLib.Source.remove(this._hideTimeoutId);
            this._hideTimeoutId = null;
        }
    }

    destroy() {
        this._cancelHide();
        this._stopDrag();
        if (this._repositionId) {
            try { Main.layoutManager.disconnect(this._repositionId); } catch (_) { }
            this._repositionId = null;
        }
        super.destroy();
    }
});

// ---------------------------------------------------------------------------
// 面板指示器（设置入口 + 手动同步 + 推送剪贴板）
// ---------------------------------------------------------------------------
const IslandIndicator = GObject.registerClass(
class IslandIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Island Sync');
        this.add_child(new St.Icon({
            icon_name: 'phone-symbolic',
            style_class: 'system-status-icon',
        }));
        this._lastSyncItem = new PopupMenu.PopupMenuItem('尚未同步');
        this.menu.addMenuItem(this._lastSyncItem);
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._syncNowItem = new PopupMenu.PopupMenuItem('立即同步');
        this.menu.addMenuItem(this._syncNowItem);
        this._testItem = new PopupMenu.PopupMenuItem('显示测试灵动岛');
        this.menu.addMenuItem(this._testItem);
        this._pushClipboardItem = new PopupMenu.PopupMenuItem('推送剪贴板到手机');
        this.menu.addMenuItem(this._pushClipboardItem);
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._aboutItem = new PopupMenu.PopupMenuItem('关于 · 作者 是天创呀');
        this.menu.addMenuItem(this._aboutItem);
    }

    setLastSync(text) {
        this._lastSyncItem.label.text = text;
    }
});

// ---------------------------------------------------------------------------
// 主扩展
// ---------------------------------------------------------------------------
export default class IslandSyncExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._session = new Soup.Session({timeout: 15});
        this._pollTimeoutId = null;
        this._lastNotifId = null;
        this._lastClipboardTs = 0;
        this._inFlight = false;
        this._fileSha = null;

        this._island = new Island(this._settings.get_int('island-duration'));
        Main.uiGroup.add_child(this._island);

        this._indicator = new IslandIndicator();
        Main.panel.addToStatusArea('islandSync', this._indicator);
        this._indicator._syncNowItem.connect('activate', () => this._poll());
        this._indicator._testItem.connect('activate', () => this._showTestIsland());
        this._indicator._pushClipboardItem.connect('activate', () => this._pushClipboard());
        this._indicator._aboutItem.connect('activate', () => {
            Main.notify('灵动岛同步 · 关于作者',
                '由 是天创呀 独立制作 © 2026\n手机↔电脑 通知与剪贴板互通');
        });

        this._initialPollId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            this._initialPollId = null;
            this._poll();
            return GLib.SOURCE_REMOVE;
        });
        this._schedulePoll(this._settings.get_int('poll-interval'));
    }

    _schedulePoll(seconds) {
        if (this._pollTimeoutId)
            GLib.Source.remove(this._pollTimeoutId);
        this._pollTimeoutId = GLib.timeout_add_seconds(
            GLib.PRIORITY_DEFAULT, Math.max(3, seconds), () => {
                this._pollTimeoutId = null;
                this._poll();
                this._schedulePoll(this._settings.get_int('poll-interval'));
                return GLib.SOURCE_REMOVE;
            });
    }

    _giteeContentUrl() {
        const owner = this._settings.get_string('gitee-owner');
        const repo = this._settings.get_string('gitee-repo');
        const branch = this._settings.get_string('gitee-branch');
        const path = this._settings.get_string('gitee-path');
        const token = this._settings.get_string('gitee-token');
        let url = `https://gitee.com/api/v5/repos/${owner}/${repo}/contents/${path}?ref=${encodeURIComponent(branch)}`;
        if (token)
            url += `&access_token=${encodeURIComponent(token)}`;
        return url;
    }

    _giteeWriteUrl() {
        return this._giteeContentUrl().split('?')[0];
    }

    _poll() {
        if (this._inFlight)
            return;
        const owner = this._settings.get_string('gitee-owner');
        const repo = this._settings.get_string('gitee-repo');
        if (!owner || !repo)
            return;

        this._inFlight = true;
        const message = Soup.Message.new('GET', this._giteeContentUrl());
        this._session.send_and_read_async(message, GLib.PRIORITY_DEFAULT, null, (session, result) => {
            this._inFlight = false;
            try {
                const bytes = session.send_and_read_finish(result);
                if (message.get_status() !== Soup.Status.OK) {
                    this._indicator?.setLastSync(`同步失败 (${message.get_status()})`);
                    return;
                }
                const payload = JSON.parse(new TextDecoder().decode(bytes.get_data()));
                // contents API 返回 {content: base64, sha}; 兼容直接放 JSON 的 raw 场景
                const data = payload.content !== undefined
                    ? JSON.parse(new TextDecoder().decode(GLib.base64_decode(payload.content)))
                    : payload;
                this._fileSha = payload.sha ?? this._fileSha;
                this._apply(data);
            } catch (error) {
                console.error(`[Island Sync] poll failed: ${error?.message ?? error}`);
                this._indicator?.setLastSync('同步出错');
            }
        });
    }

    _apply(data) {
        const notifications = Array.isArray(data?.notifications) ? data.notifications : [];
        const latest = notifications.length > 0 ? notifications[notifications.length - 1] : null;
        if (latest && latest.id && latest.id !== this._lastNotifId) {
            const ts = Number(latest.ts ?? latest.updated ?? 0);
            const isRecentFirstSync = this._lastNotifId === null && ts > Date.now() - 120000;
            const isNew = this._lastNotifId !== null || isRecentFirstSync;
            this._lastNotifId = latest.id;
            console.log(`[Island Sync] latest notification id=${latest.id} new=${isNew}`);
            if (isNew && this._shouldShowNotification(latest)) {
                const opener = this._canOpenApp(latest.app) ? app => this._openApp(app) : null;
                this._island.showNotification(latest, opener);
            }
        }

        if (this._settings.get_boolean('clipboard-sync') && data?.clipboard?.text) {
            const ts = data.clipboard.ts ?? 0;
            if (ts > this._lastClipboardTs && data.clipboard.from === 'phone') {
                this._lastClipboardTs = ts;
                const clipboard = St.Clipboard.get_default();
                clipboard.set_text(St.ClipboardType.CLIPBOARD, String(data.clipboard.text));
                Main.notify('剪贴板已同步', String(data.clipboard.text).slice(0, 80));
            }
        }

        this._indicator?.setLastSync(
            `上次同步 ${new Date().toLocaleTimeString()} · ${notifications.length} 条通知`);
    }

    _openApp(app) {
        const map = this._parseJson(this._settings.get_string('launch-map'), {});
        const command = map[app];
        if (command)
            Util.spawnCommandLine(command);
        else
        Main.notify('灵动岛', `没有配置 ${app} 的启动命令（在扩展设置 launch-map 中添加）`);
    }

    _shouldShowNotification(notif) {
        const watchApps = this._parseJson(this._settings.get_string('watch-apps'), []);
        if (!Array.isArray(watchApps) || watchApps.length === 0)
            return true;
        return watchApps.includes(notif.app) ||
            watchApps.includes(notif.packageName) ||
            watchApps.includes(notif.appLabel);
    }

    _canOpenApp(app) {
        const map = this._parseJson(this._settings.get_string('launch-map'), {});
        return Boolean(map[app]);
    }

    _showTestIsland() {
        this._island?.showNotification({
            id: `local-test-${Date.now()}`,
            app: 'wechat',
            title: '灵动岛本地测试',
            text: '这是一条电脑端自测消息：如果药丸弹出、点击能展开玻璃卡片，并且这段较长的文字能按当前屏幕宽度自动换行、不把按钮挤出边框，说明扩展 UI 链路已经正常。现在也支持拖动顶部药丸或卡片标题栏，位置会自动保存。',
            ts: Date.now(),
        }, app => this._openApp(app));
    }

    // 电脑剪贴板 → 手机（手动触发，避免每次复制都产生 Gitee 提交）
    _pushClipboard() {
        const owner = this._settings.get_string('gitee-owner');
        const repo = this._settings.get_string('gitee-repo');
        if (!owner || !repo) {
            Main.notify('灵动岛', '请先在扩展设置中填写 Gitee 仓库信息');
            return;
        }
        const clipboard = St.Clipboard.get_default();
        clipboard.get_text(St.ClipboardType.CLIPBOARD, (_clipboard, text) => {
            this._writeRemote(data => {
                data.clipboard = {text: text || '', ts: Date.now(), from: 'pc'};
                return data;
            }, ok => {
                Main.notify('灵动岛', ok ? '剪贴板已推送到 Gitee，手机端可获取' : '推送失败，请检查令牌/仓库配置');
            });
        });
    }

    _writeRemote(mutate, callback) {
        const readMessage = Soup.Message.new('GET', this._giteeContentUrl());
        this._session.send_and_read_async(readMessage, GLib.PRIORITY_DEFAULT, null, (session, result) => {
            try {
                const bytes = session.send_and_read_finish(result);
                let current = {};
                let sha = null;
                if (readMessage.get_status() === Soup.Status.OK) {
                    const payload = JSON.parse(new TextDecoder().decode(bytes.get_data()));
                    if (Array.isArray(payload)) {
                        current = {};
                    } else {
                        current = payload.content !== undefined
                            ? JSON.parse(new TextDecoder().decode(GLib.base64_decode(payload.content)))
                            : {};
                        sha = payload.sha ?? null;
                    }
                } else if (readMessage.get_status() !== Soup.Status.NOT_FOUND) {
                    callback?.(false);
                    return;
                }
                const next = mutate(current);
                next.updated = Date.now();

                const token = this._settings.get_string('gitee-token');
                const branch = this._settings.get_string('gitee-branch');
                const body = JSON.stringify({
                    access_token: token,
                    branch,
                    sha,
                    message: 'island-sync: update',
                    content: GLib.base64_encode(new TextEncoder().encode(JSON.stringify(next))),
                });
                const writeMessage = Soup.Message.new(sha ? 'PUT' : 'POST', this._giteeWriteUrl());
                writeMessage.set_request_body_from_bytes('application/json',
                    new GLib.Bytes(body));
                this._session.send_and_read_async(writeMessage, GLib.PRIORITY_DEFAULT, null, (sess, res) => {
                    try {
                        const writeBytes = sess.send_and_read_finish(res);
                        const status = writeMessage.get_status();
                        const ok = status >= 200 && status < 300 && writeBytes.get_data().length > 0;
                        callback?.(ok);
                    } catch (_) {
                        callback?.(false);
                    }
                });
            } catch (_) {
                console.error('[Island Sync] writeRemote read/mutate failed');
                callback?.(false);
            }
        });
    }

    _parseJson(text, fallback) {
        try {
            return JSON.parse(text);
        } catch (_) {
            return fallback;
        }
    }

    disable() {
        if (this._pollTimeoutId) {
            GLib.Source.remove(this._pollTimeoutId);
            this._pollTimeoutId = null;
        }
        if (this._initialPollId) {
            GLib.Source.remove(this._initialPollId);
            this._initialPollId = null;
        }
        if (this._island) {
            this._island.destroy();
            this._island = null;
        }
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
        this._session = null;
        this._settings = null;
    }
}
