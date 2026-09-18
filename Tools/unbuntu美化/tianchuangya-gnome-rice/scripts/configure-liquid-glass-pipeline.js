#!/usr/bin/gjs -m

// 液态玻璃管线参数 v2 —— 参考 Apple Liquid Glass / cocos 位移贴图折射配方 /
// liquid-glass-react (displacementScale, aberrationIntensity, overLight)。
//
// 设计原则：
//  * Dock 是"底层清玻璃"：中心不染色不模糊发黑，折射与泛光只发生在边缘；
//  * 弹出面板是"磨砂玻璃"：动态模糊 + 自适应蒙层保证文字可读（分层材质）。

import Gio from 'gi://Gio';
import {
  pack_pipelines,
  unpack_pipelines,
} from 'file:///home/tianchuangya/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/conveniences/pipeline_settings.js';

const schemaDirectory = '/home/tianchuangya/.local/share/gnome-shell/extensions/blur-my-shell@aunetx/schemas';
const parentSource = Gio.SettingsSchemaSource.get_default();
const source = Gio.SettingsSchemaSource.new_from_directory(schemaDirectory, parentSource, false);
const schema = source.lookup('org.gnome.shell.extensions.blur-my-shell', false);
const settings = Gio.Settings.new_full(schema, null, null);

const pipelines = unpack_pipelines(settings.get_value('pipelines'));

// Dock：透明清玻璃。tint 0 保持中心完全无色；edge 折射 + 色散 + 边缘泛光。
pipelines.liquid_glass_dock = {
  name: 'Liquid Glass Dock',
  effects: [
    {
      type: 'refraction',
      id: 'effect_liquid_glass_dock_refraction',
      params: {
        strength: 0.24,
        blur_radius: 2,
        edge_size: 18,
        falloff: 2.6,
        corner_radius: 28,
        rim_width: 2.6,
        rgb_fringing: 0.015,
        gloss: 0.30,
        tint: 0.0,
        tint_color: [1.0, 1.0, 1.0, 1.0],
        backdrop_zoom: 1.0,
        shadow: 0.10,
        texture_repeat: 0,
      },
    },
  ],
};

// 应用窗口（未默认启用，保留清玻璃取向）。
pipelines.liquid_glass_apps = {
  name: 'Liquid Glass Apps',
  effects: [
    {
      type: 'refraction',
      id: 'effect_liquid_glass_apps_refraction',
      params: {
        strength: 0.20,
        blur_radius: 2,
        edge_size: 16,
        falloff: 2.6,
        corner_radius: 24,
        rim_width: 2.4,
        rgb_fringing: 0.012,
        gloss: 0.26,
        tint: 0.01,
        tint_color: [1.0, 1.0, 1.0, 1.0],
        backdrop_zoom: 1.0,
        shadow: 0.10,
        texture_repeat: 0,
      },
    },
  ],
};

// 弹出层（静态折射路径备用；当前弹出层走动态模糊 + CSS 蒙层）。
pipelines.liquid_glass_popup = {
  name: 'Liquid Glass Popups',
  effects: [
    {
      type: 'refraction',
      id: 'effect_liquid_glass_popup_refraction',
      params: {
        strength: 0.16,
        blur_radius: 8,
        edge_size: 14,
        falloff: 2.4,
        corner_radius: 24,
        rim_width: 2.0,
        rgb_fringing: 0.010,
        gloss: 0.16,
        tint: 0.015,
        tint_color: [1.0, 1.0, 1.0, 1.0],
        backdrop_zoom: 1.0,
        shadow: 0.14,
        texture_repeat: 0,
      },
    },
  ],
};

settings.set_value('pipelines', pack_pipelines(pipelines));
Gio.Settings.sync();

print('liquid glass pipelines configured (v2 clear-edge style)');
