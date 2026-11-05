"""Optimize isolated Poly Haven source objects in a separate Blender process.
Source .blend libraries contain only the imported asset IDs, never the user's working scene.
"""
import bpy,os,json,math,numpy as np
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT=os.path.join(ROOT,'assets/models/real_props');os.makedirs(OUT,exist_ok=True)
results={}
for kind,prefix,size,ratio in [('rock_face','rock_face_02',4.8,.3),('wooden_crate','wooden_crate_01',.9,.5),('covered_car','covered_car',4.5,.7),('overhead_crane','overhead_crane',12.5,.18),('industrial_container','industrial_pastic_container',.65,.7),('island_home','modular_urban_apartments_facade',9,.3),('island_block','modular_urban_apartments_facade',12,.3),('shipping_container','shipping_container',6,.9),('speedboat','boat-speed-b',5,.95),('tugboat','boat-tug-a',12,.95),('cargo_ship','ship-cargo-c',26,.95)]:
    for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
    path=os.path.join(ROOT,'tools/.cache/real-prop-sources',prefix+'.blend')
    if kind in ['shipping_container','speedboat','tugboat','cargo_ship']:
        bpy.ops.import_scene.gltf(filepath=path.replace('.blend','.glb'))
        metal=bpy.data.materials.new('Weathered painted steel');metal.diffuse_color=(.16,.29,.31,1);metal.use_nodes=True
        shader=next(n for n in metal.node_tree.nodes if n.type=='BSDF_PRINCIPLED');shader.inputs['Base Color'].default_value=(.16,.29,.31,1);shader.inputs['Metallic'].default_value=.35;shader.inputs['Roughness'].default_value=.7
        if kind=='shipping_container':
            for o in bpy.context.scene.objects:
                if o.type=='MESH':o.data.materials.clear();o.data.materials.append(metal)
    else:
        with bpy.data.libraries.load(path,link=False) as (source,target):target.objects=list(source.objects)
        for o in target.objects:
            if o is not None:bpy.context.scene.collection.objects.link(o)
    bpy.context.view_layer.update()
    if kind in ['island_home','island_block']:
        # Assemble only matching facade modules, not the library's catalogue layout.
        sources={o.name.split('.')[0]:o for o in list(bpy.context.scene.objects)}
        from mathutils import Matrix
        def module(name,origin,angle=0):
            src=sources[name];obj=src.copy();obj.data=src.data.copy();obj.parent=None
            anchor=sources[name if name.startswith('wall_') else 'wall_'+name]
            pts=[anchor.matrix_world@v.co for v in anchor.data.vertices]
            shift=Vector((min(v.x for v in pts),0,min(v.z for v in pts)))
            for v in obj.data.vertices:v.co=src.matrix_world@v.co-shift
            obj.matrix_world=Matrix.Translation(Vector(origin))@Matrix.Rotation(angle,4,'Z');bpy.context.scene.collection.objects.link(obj)
        floors=1 if kind=='island_home' else 2
        for floor in range(floors):
            for side in range(4):
                angle=side*math.pi/2;rotation=Matrix.Rotation(angle,4,'Z')
                for col in range(3):
                    origin=rotation@Vector((-4.5+3*col,-4.5,0))+Vector((0,0,3*floor))
                    pair=['wall_door_centered_small_01','door_centered_small_01'] if side==0 and col==1 and floor==0 else ['wall_window_centered_small_01','window_centered_small_01']
                    for name in pair:module(name,origin,angle)
        for src in sources.values():bpy.data.objects.remove(src,do_unlink=True)
        bpy.ops.mesh.primitive_cube_add(size=1,location=(0,0,3*floors+.15));roof=bpy.context.object;roof.scale=(9.5,9.5,.3)
        roofmat=bpy.data.materials.new('Coastal roof');roofmat.use_nodes=True;next(n for n in roofmat.node_tree.nodes if n.type=='BSDF_PRINCIPLED').inputs['Base Color'].default_value=(.20,.27,.25,1);roof.data.materials.append(roofmat)
        # Weather protection and ground trim stay within the existing building footprint.
        for z in [0,3*floors]:
            bpy.ops.mesh.primitive_cube_add(size=1,location=(0,0,z+.08));trim=bpy.context.object;trim.scale=(9.15,9.15,.16);trim.data.materials.append(roofmat)
        def detail(name,at,scale):
            bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.name=name;o.scale=scale;o.data.materials.append(roofmat)
        detail('Entrance rain canopy',(0,-4.3,2.6),(2.8,.85,.12))
        for x in [-1.25,1.25]:detail('Canopy wall bracket',(x,-4.4,2.3),(.08,.15,.6))
        for x in [-4.35,4.35]:detail('Facade downpipe',(x,-4.52,1.5),(.07,.07,3))
        detail('Door landing',(0,-4.3,.06),(2.6,.8,.12))
        bpy.context.view_layer.update()
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for image in bpy.data.images:
        if image.name.startswith('colormap'):
            image.filepath=os.path.join(ROOT,'assets/models/watercraft/Textures/colormap.png')
            image.reload()
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    if len(objects)>1:bpy.ops.object.join()
    node=bpy.context.object;node.name=kind
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    coords=[v.co for v in node.data.vertices]
    lo=Vector(tuple(min(p[a] for p in coords) for a in range(3)));hi=Vector(tuple(max(p[a] for p in coords) for a in range(3)))
    factor=size/max(hi-lo);offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    for v in node.data.vertices:v.co=(v.co-offset)*factor
    dec=node.modifiers.new('Mobile geometry budget','DECIMATE');dec.ratio=ratio
    bpy.ops.object.modifier_apply(modifier=dec.name)
    lo_z=min(v.co.z for v in node.data.vertices)
    for v in node.data.vertices:v.co.z-=lo_z
    if kind in ['island_home','island_block']:
        height=max(v.co.z for v in node.data.vertices)
        for v in node.data.vertices:v.co.z*= (3.25 if kind=='island_home' else 6.25)/height
    for face in node.data.polygons:face.use_smooth=True
    node.data.update();bpy.context.view_layer.update()
    coords=[v.co for v in node.data.vertices]
    lo=Vector(tuple(min(p[a] for p in coords) for a in range(3)));hi=Vector(tuple(max(p[a] for p in coords) for a in range(3)))
    # Keep the mobile textures small even when a source library offers an 8K preview.
    image_cache={}
    for mat in set(node.data.materials):
        if not mat or not mat.use_nodes:continue
        for tex in mat.node_tree.nodes:
            if tex.type!='TEX_IMAGE' or not tex.image:continue
            key=(tex.image.filepath,tex.image.colorspace_settings.name)
            if key in image_cache:
                tex.image=image_cache[key];continue
            image=tex.image.copy();limit=512 if 'diff' in image.name.lower() else 256
            if max(image.size)>limit:
                scale=limit/max(image.size);image.scale(max(1,int(image.size[0]*scale)),max(1,int(image.size[1]*scale)))
            if image.is_float:
                pixels=np.empty(image.size[0]*image.size[1]*4,dtype=np.float32);image.pixels.foreach_get(pixels)
                byte_image=bpy.data.images.new(image.name+'_mobile',width=image.size[0],height=image.size[1],float_buffer=False)
                byte_image.colorspace_settings.name=image.colorspace_settings.name;byte_image.pixels.foreach_set(pixels);image=byte_image
            tex.image=image;image.pack();image_cache[key]=image
    bpy.data.orphans_purge(do_recursive=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art/blender','optimized_'+kind+'.blend'),compress=True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,kind+'.glb'),export_format='GLB',use_selection=True,export_apply=True)
    results[kind]={'triangles':sum(len(p.vertices)-2 for p in node.data.polygons),'size':[hi.x-lo.x,hi.z-lo.z,hi.y-lo.y],'min':[lo.x,lo.z,-hi.y],'max':[hi.x,hi.z,-lo.y],'source':('https://kenney.nl/assets/watercraft-kit' if kind in ['shipping_container','speedboat','tugboat','cargo_ship'] else 'https://polyhaven.com/a/'+prefix),'license':'CC0'}
    print('OPTIMIZED',kind,results[kind])
json.dump(results,open(os.path.join(OUT,'asset_info.json'),'w'),indent=2)
