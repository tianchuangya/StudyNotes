import Adw from 'gi://Adw';
import Gtk from 'gi://Gtk';

import {ExtensionPreferences} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class IslandSyncPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();

        const page = new Adw.PreferencesPage({
            title: '灵动岛同步',
            icon_name: 'phone-symbolic',
        });

        const giteeGroup = new Adw.PreferencesGroup({
            title: 'Gitee 中转仓库',
            description: '建议使用私有仓库和只用于本项目的私人令牌。',
        });
        page.add(giteeGroup);

        this._addStringRow(giteeGroup, settings, 'gitee-owner', 'Gitee 用户名 / 组织');
        this._addStringRow(giteeGroup, settings, 'gitee-repo', '仓库名');
        this._addStringRow(giteeGroup, settings, 'gitee-branch', '分支');
        this._addStringRow(giteeGroup, settings, 'gitee-path', 'JSON 文件路径');
        this._addStringRow(giteeGroup, settings, 'gitee-token', '私人令牌', true);

        const behaviorGroup = new Adw.PreferencesGroup({
            title: '同步行为',
        });
        page.add(behaviorGroup);

        this._addSpinRow(behaviorGroup, settings, 'poll-interval', '轮询间隔（秒）', 3, 120);
        this._addSpinRow(behaviorGroup, settings, 'island-duration', '灵动岛显示时长（秒）', 2, 30);
        this._addSwitchRow(behaviorGroup, settings, 'clipboard-sync', '启用手机 → 电脑剪贴板同步');
        this._addStringRow(behaviorGroup, settings, 'watch-apps', '监听应用列表（JSON 数组）');
        this._addStringRow(behaviorGroup, settings, 'launch-map', '应用启动命令映射（JSON）');

        window.add(page);
    }

    _addStringRow(group, settings, key, title, password = false) {
        const row = password
            ? new Adw.PasswordEntryRow({title})
            : new Adw.EntryRow({title});
        row.text = settings.get_string(key);
        row.connect('changed', () => {
            settings.set_string(key, row.text);
        });
        group.add(row);
    }

    _addSpinRow(group, settings, key, title, lower, upper) {
        const row = new Adw.SpinRow({
            title,
            adjustment: new Gtk.Adjustment({
                lower,
                upper,
                step_increment: 1,
                page_increment: 5,
                value: settings.get_int(key),
            }),
        });
        row.connect('notify::value', () => {
            settings.set_int(key, row.value);
        });
        group.add(row);
    }

    _addSwitchRow(group, settings, key, title) {
        const row = new Adw.SwitchRow({
            title,
            active: settings.get_boolean(key),
        });
        row.connect('notify::active', () => {
            settings.set_boolean(key, row.active);
        });
        group.add(row);
    }
}
