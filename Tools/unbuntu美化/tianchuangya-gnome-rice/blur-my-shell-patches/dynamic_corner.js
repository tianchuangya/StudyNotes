import Clutter from 'gi://Clutter';

/// Round the corners of a *dynamic* blur layer.
///
/// GNOME 46's `Shell.BlurEffect` samples the live scene behind the actor
/// (correct layering, unlike static blur) but always paints a rectangle.
/// Chaining this helper's `corner` effect (corner.glsl) as the outermost
/// effect makes the blur layer itself rounded, so it matches the CSS
/// rounded outline of the popup/dock painted on top of it.
///
/// The same pattern is already used for static blur in
/// `components/popup/static_corner.js`; this variant tracks the actor's
/// allocation so the shader's width/height uniforms stay in sync while
/// the popup or dock resizes.
export const DynamicCornerRounded = class DynamicCornerRounded {
    constructor(effects_manager, actor, get_radius) {
        this._actor = actor;
        this._get_radius = get_radius;
        this._allocation_id = 0;
        this._destroy_id = 0;
        this._effect = effects_manager.new_corner_effect({ radius: get_radius() });
        actor.add_effect(this._effect);
        this._update_size();
        this._allocation_id = actor.connect('notify::allocation', () => this._update_size());
        this._destroy_id = actor.connect('destroy', () => this.destroy());
    }

    _update_size() {
        if (!this._actor || !this._effect)
            return;
        try {
            const [width, height] = this._actor.get_size();
            this._effect.width = Math.max(1, width);
            this._effect.height = Math.max(1, height);
            this._effect.radius = Math.max(0, this._get_radius());
        } catch (e) { }
    }

    set_radius(radius) {
        if (this._effect)
            this._effect.radius = Math.max(0, radius);
    }

    destroy() {
        if (this._allocation_id && this._actor) {
            try { this._actor.disconnect(this._allocation_id); } catch (e) { }
        }
        if (this._destroy_id && this._actor) {
            try { this._actor.disconnect(this._destroy_id); } catch (e) { }
        }
        this._allocation_id = 0;
        this._destroy_id = 0;
        this._actor = null;
        // EffectsManager pools effects; removing detaches and recycles it
        if (this._effect) {
            try {
                const actor = this._effect.get_actor();
                if (actor)
                    actor.remove_effect(this._effect);
            } catch (e) { }
        }
        this._effect = null;
    }
};
