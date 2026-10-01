import sys
import bpy


def main():
    if "--" not in sys.argv:
        raise SystemExit("Usage: blender --background --python blender_convert.py -- input.glb output.fbx")

    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) < 2:
        raise SystemExit("Usage: blender --background --python blender_convert.py -- input.glb output.fbx")

    input_path, output_path = args[0], args[1]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=input_path)

    objects = list(bpy.context.scene.objects)
    if not objects:
        raise RuntimeError("No objects were imported from the GLB file")

    bpy.ops.object.select_all(action="SELECT")
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.fbx(
        filepath=output_path,
        use_selection=False,
        object_types={"MESH", "ARMATURE", "EMPTY"},
        path_mode="COPY",
        embed_textures=True,
        add_leaf_bones=False,
        bake_anim=False,
        apply_unit_scale=True,
        axis_forward="-Z",
        axis_up="Y",
    )
    print(f"Imported objects: {len(objects)}")
    print(f"Exported: {output_path}")


if __name__ == "__main__":
    main()
