"""Rebuild clean island houses and a lightweight animated fishing splash in Blender.
Run with Blender --background --python tools/blender_refine_island.py.
"""
import bpy, bmesh, json, math, os, ast, re
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "models", "island_refined")
os.makedirs(OUT, exist_ok=True)
SOURCE = os.path.join(ROOT,"art","blender")
os.makedirs(SOURCE,exist_ok=True)
scene = bpy.context.scene
for obj in list(bpy.data.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
scene.unit_settings.system = 'METRIC'

def xyz(v):
    return (v[0], -v[2], v[1])

def material(name, color, roughness=.8):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    node = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value = (*color, 1)
    node.inputs['Roughness'].default_value = roughness
    mat.diffuse_color = (*color, 1)
    return mat

mats = {
    'board': material('board', (.72,.77,.68)),
    'iron': material('iron', (.48,.57,.57), .55),
    'concrete': material('concrete', (.58,.59,.54)),
    'paint': material('paint', (.85,.83,.74)),
    'wood': material('wood', (.38,.27,.16)),
    'glass': material('glass', (.19,.30,.32), .2),
}
colliders = []

def cube(name, center, size, key, collide=False):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz(center))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = (size[0], size[2], size[1])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mats[key])
    if collide:
        colliders.append({'name': name, 'center': list(center), 'size': list(size)})
    return obj

def mesh(name, vertices, faces, key):
    data=bpy.data.meshes.new(name)
    data.from_pydata([xyz(v) for v in vertices], [], faces)
    data.update()
    obj=bpy.data.objects.new(name,data)
    scene.collection.objects.link(obj)
    obj.data.materials.append(mats[key])
    return obj

def make_house():
    cube('Foundation', (0,.16,0), (8.3,.32,10.3), 'concrete', True)
    cube('ClosedHome', (0,1.785,0), (8,2.93,10), 'board', True)
    # Closed gables follow the roof precisely; no diagonal bars protruding from the roof.
    mesh('Gables', [(-4,3.25,-5),(-4,3.25,5),(-4,4.65,0),(4,3.25,-5),(4,4.65,0),(4,3.25,5)],[(0,1,2),(3,4,5)],'board')
    for sign in [-1,1]:
        eave=sign*5.38
        vertices=[(-4.38,3.14,eave),(4.38,3.14,eave),(4.38,4.65,0),(-4.38,4.65,0),
                  (-4.38,3.06,eave),(4.38,3.06,eave),(4.38,4.57,0),(-4.38,4.57,0)]
        mesh('SealedRoof_%s'%sign,vertices,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],'iron')
    cube('RidgeCap',(0,4.67,0),(8.8,.09,.24),'iron')
    for sign in [-1,1]:
        cube('Fascia',(0,3.12,sign*5.38),(8.8,.15,.08),'paint')
    # Tight window trims: four strips, rather than a solid panel through the glazing.
    for x in [-2.4,2.4]:
        cube('Glazing',(x,1.98,5.028),(1.65,1.25,.045),'glass')
        for xx in [-.86,.86]: cube('WindowJamb',(x+xx,1.98,5.075),(.07,1.4,.08),'paint')
        for y in [1.32,2.64]: cube('WindowRail',(x,y,5.075),(1.78,.07,.08),'paint')
        cube('WindowMullion',(x,1.98,5.085),(.045,1.25,.045),'paint')
    cube('Door',(0,1.39,5.035),(.98,2.14,.07),'wood')
    cube('PorchDeck',(0,.16,6.05),(6.7,.32,2.1),'concrete',True)
    for x in [-3.12,3.12]: cube('PorchPost',(x,1.59,6.85),(.14,2.54,.14),'wood',True)
    mesh('PorchRoof',[(-3.5,2.88,7.16),(3.5,2.88,7.16),(3.5,3.13,4.97),(-3.5,3.13,4.97),
                      (-3.5,2.80,7.16),(3.5,2.80,7.16),(3.5,3.05,4.97),(-3.5,3.05,4.97)],
                     [(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],'iron')
    cube('LowerStep',(0,.055,7.58),(1.6,.11,.36),'concrete',True)
    cube('UpperStep',(0,.16,7.24),(1.6,.32,.34),'concrete',True)

def export(path, animation=False):
    props=bpy.ops.export_scene.gltf.get_rna_type().properties
    formats=[i.identifier for i in props['export_format'].enum_items]
    fmt=next((v for v in formats if v=='GLB'), props['export_format'].default)
    kwargs=dict(filepath=path,export_format=fmt,use_selection=True,export_animations=animation,export_yup=True)
    if 'export_anim_scene_split_object' in props: kwargs['export_anim_scene_split_object']=False
    if 'export_animation_mode' in props:
        modes=[i.identifier for i in props['export_animation_mode'].enum_items]
        kwargs['export_animation_mode']=next((v for v in modes if v=='SCENE'), '')
    for attempt in range(3):
        try:
            bpy.ops.export_scene.gltf(**kwargs)
            return
        except TypeError as error:
            # Dynamic exporter enums are empty in RNA until invoked; its exception is authoritative.
            choices=ast.literal_eval(re.search(r'not found in (\([^\n]+\))',str(error)).group(1))
            if not kwargs['export_format']:
                kwargs['export_format']=next(v for v in choices if v.endswith('LB'))
            elif 'export_animation_mode' in kwargs and not kwargs['export_animation_mode']:
                kwargs['export_animation_mode']=next(v for v in choices if v=='SCENE')
            else: raise

make_house()
for obj in scene.objects:
    if obj.type!='MESH': continue
    bm=bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data); bm.free()
bpy.ops.object.select_all(action='SELECT')
export(os.path.join(OUT,'coastal_house.glb'))
with open(os.path.join(OUT,'house_colliders.json'),'w') as f:
    json.dump({'dimensions':[8,10],'boxes':colliders},f,indent=2)
house_objects=list(scene.objects)
for obj in house_objects: obj.hide_set(True); obj.select_set(False)

# Animated geometry splash: short-lived mesh animation, no simulated fluid or expensive particles.
water=material('SplashWater',(.62,.86,.91),.22)
node=next(n for n in water.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
node.inputs['Metallic'].default_value=.08
scene.render.fps=30
scene.frame_start=1
scene.frame_end=28
splash_objects=[]
for i in range(10):
    angle=i*math.tau/10
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.035,location=(0,0,0))
    obj=bpy.context.object; obj.name='Droplet_%02d'%i
    obj.data.materials.append(water)
    for frame,t in [(1,0),(7,.24),(16,.62),(28,1.0)]:
        radius=t*(.35+.04*(i%3))
        obj.location=xyz((math.cos(angle)*radius,max(0,t*1.8-t*t*1.8),math.sin(angle)*radius))
        obj.scale=(.6,.6,1.5) if t<.8 else (.001,.001,.001)
        obj.keyframe_insert(data_path='location',frame=frame)
        obj.keyframe_insert(data_path='scale',frame=frame)
    splash_objects.append(obj)
for obj in splash_objects: obj.select_set(True)
scene.frame_set(1)
export(os.path.join(OUT,'fishing_splash.glb'),True)
for obj in splash_objects: obj.hide_set(True); obj.select_set(False)
for obj in house_objects: obj.hide_set(False); obj.select_set(True)
scene.frame_set(1)
# Retain an editable authoring file; exports deliberately omit cameras, lights and collision proxies.
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SOURCE,'island_refined.blend'))
triangles=sum(len(p.vertices)-2 for o in house_objects if o.type=='MESH' for p in o.data.polygons)
print('ISLAND_BLENDER_RESULT '+json.dumps({'house_triangles':triangles,'colliders':len(colliders),'house_objects':len(house_objects),'splash_objects':len(splash_objects),'output':OUT}))
# Collision proxies per connected component preserve gaps under tables and between shelter posts.
proxy_data={}
for filename in ['village_well','island_shelter','campfire_pit','spa_furniture','coconut','driftwood']:
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT,'assets','models','props',filename+'.glb'))
    imported=[o for o in bpy.data.objects if o not in before]
    boxes=[]; all_points=[]
    for obj in imported:
        if obj.type!='MESH': continue
        points=[obj.matrix_world@v.co for v in obj.data.vertices]
        all_points.extend(points)
        if any(v in obj.name.lower() for v in ['foliage','rope','waterdisk','bottle']): continue
        links=[[] for _ in points]
        weld={}
        for idx,p in enumerate(points):
            key=tuple(round(c,5) for c in p)
            if key in weld:
                other=weld[key]; links[idx].append(other); links[other].append(idx)
            else: weld[key]=idx
        for edge in obj.data.edges:
            a,b=edge.vertices; links[a].append(b); links[b].append(a)
        visited=set()
        for first in range(len(points)):
            if first in visited: continue
            stack=[first]; component=[]; visited.add(first)
            while stack:
                idx=stack.pop(); component.append(points[idx])
                for nxt in links[idx]:
                    if nxt not in visited: visited.add(nxt); stack.append(nxt)
            if len(component)<4: continue
            converted=[Vector((p.x,p.z,-p.y)) for p in component]
            low=Vector(tuple(min(p[a] for p in converted) for a in range(3)))
            high=Vector(tuple(max(p[a] for p in converted) for a in range(3)))
            size=high-low
            if max(size)<.05: continue
            boxes.append({'name':obj.name,'center':list((low+high)*.5),'size':[max(.025,v) for v in size]})
    converted=[Vector((p.x,p.z,-p.y)) for p in all_points]
    low=[min(p[a] for p in converted) for a in range(3)]
    high=[max(p[a] for p in converted) for a in range(3)]
    proxy_data[filename]={'min':low,'max':high,'boxes':boxes}
    for obj in imported: bpy.data.objects.remove(obj,do_unlink=True)
with open(os.path.join(OUT,'prop_physics.json'),'w') as file: json.dump(proxy_data,file)
print('PROXY_COMPONENTS '+json.dumps({k:len(v['boxes']) for k,v in proxy_data.items()}))
# Review render is separate from the authoring file.
for obj in bpy.context.selected_objects: obj.select_set(False)
bpy.ops.object.camera_add(location=(15,-22,15))
camera=bpy.context.object
camera.rotation_euler=(Vector((0,-1,2))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO'; camera.data.ortho_scale=19
scene.camera=camera
for at,power,size in [((3,-8,13),1900,9),((-8,2,8),1100,8)]:
    bpy.ops.object.light_add(type='AREA', location=at)
    light=bpy.context.object
    light.data.energy=power; light.data.shape='DISK'; light.data.size=size
    light.rotation_euler=(Vector((0,0,2))-light.location).to_track_quat('-Z','Y').to_euler()
scene.world.color=(.30,.35,.40)
scene.render.resolution_x=850; scene.render.resolution_y=650; scene.render.resolution_percentage=100
scene.render.filepath=os.path.join(ROOT,'checks','blender-house-preview.png')
scene.render.image_settings.file_format='PNG'
bpy.ops.render.render(write_still=True)
