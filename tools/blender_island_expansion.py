"""Blender-authored wharf, fictional-name nakamal and aerial menu render.
Locations follow supplied Maps pins; unseen architecture is interpreted.
Run with Blender --background --python tools/blender_island_expansion.py.
"""
import bpy, json, math, os, random
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT=os.path.join(ROOT,'assets/models/island_expansion');os.makedirs(OUT,exist_ok=True)
ART=os.path.join(ROOT,'art/blender');os.makedirs(ART,exist_ok=True)
def clear():
    for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
def material(name,color,rough=.8,emit=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough
    if emit:p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=emit
    return m
clear()
mats={k:material(k,c) for k,c in {'concrete':(.47,.48,.45),'cream':(.83,.82,.71),'roof':(.39,.45,.43),'steel':(.12,.16,.17),'wood':(.32,.19,.10),'red':(.56,.15,.10),'blue':(.10,.28,.37),'green':(.16,.34,.23),'yellow':(.83,.56,.10),'glass':(.12,.25,.29)}.items()}
mats['lamp']=material('Warm lantern',(.95,.58,.18),.6,1.8)
colliders=[]
def box(name,at,size,key,solid=False,root=None):
    x,y,z=at;w,h,d=size;bpy.ops.mesh.primitive_cube_add(size=1,location=(x,-z,y));o=bpy.context.object;o.name=name;o.dimensions=(w,d,h);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[key]);o.parent=root
    if solid:colliders.append({'center':at,'size':size})
    return o
def cylinder(name,at,r,h,key,root=None):
    x,y,z=at;bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=h,location=(x,-z,y));o=bpy.context.object;o.name=name;o.data.materials.append(mats[key]);o.parent=root;return o
def lettering(value,at,size,key):
    c=bpy.data.curves.new(value,'FONT');c.body=value;c.size=size;c.align_x='CENTER';c.extrude=.002
    o=bpy.data.objects.new(value,c);bpy.context.collection.objects.link(o);o.location=(at[0],-at[2],at[1]);o.rotation_euler.x=math.pi/2;c.materials.append(mats[key]);bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False)
def export(name,groups=(None,)):
    for group in groups:
        for m in list(bpy.data.materials):
            objects=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==group and len(o.data.materials) and o.data.materials[0]==m]
            if not objects:continue
            bpy.ops.object.select_all(action='DESELECT')
            for o in objects:o.select_set(True)
            bpy.context.view_layer.objects.active=objects[0]
            if len(objects)>1:bpy.ops.object.join()
            objects[0].name=m.name
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ART,name+'.blend'))
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,name+'.glb'),export_format='GLB')
    with open(os.path.join(OUT,name+'_collision.json'),'w') as f:json.dump(colliders,f)

# Ifira: compact container terminal, warehouse, reach stacker and public quay.
box('Wharf deck',(0,-.2,0),(48,.4,32),'concrete',True)
box('Warehouse rear',(10,3,-13),(22,6,.2),'cream',True)
for x in [-1,21]:box('Warehouse side',(x,3,-6),(.2,6,14),'cream',True)
for x in [2.2,17.8]:box('Warehouse front',(x,3,1),(6.4,6,.2),'cream',True)
box('Warehouse door lintel',(10,5.65,1),(9.2,.7,.2),'cream',True)
for side in [-1,1]:
    o=box('Roof panel',(10,6.65,-6+side*3.6),(23,.13,7.6),'roof');o.rotation_euler.x=side*.18
box('Office',(15,1.5,6),(11,3,7),'cream',True)
for x in [12,15,18]:box('Office window',(x,1.8,9.55),(2.1,1.3,.05),'glass')
box('Blue sign',(15,3.18,9.6),(12,.65,.08),'blue')
lettering('IFIRA PORT DEVELOPMENT SERVICES',(15,3.06,9.66),.28,'cream')
for x in [-23.3]:
    for z in [-13,-7,0,7,13]:
        cylinder('Mooring bollard',(x,.35,z),.25,.7,'steel');colliders.append({'center':(x,.35,z),'size':(.5,.7,.5)})
# Static reach stacker with cab, tyre pairs and a high telescopic boom.
box('Reach stacker chassis',(-2,.8,8),(3.5,1.2,5.2),'yellow',True)
box('Glass cab',(-2,2.1,7.3),(2.1,1.8,2.0),'glass',True)
for x in [-3.65,-.35]:
    for z in [6.1,9.5]:
        o=cylinder('Stacker tyre',(x,.65,z),.7,.45,'steel');o.rotation_euler.y=math.pi/2
o=box('Lifting boom',(-2,4.5,10),(1.0,6,.8),'yellow');o.rotation_euler.x=.38
box('Container spreader',(-2,6.9,12.1),(6,.25,1.0),'steel')
for x in [-22,-10]:box('Quay crane tower',(x,5,12),(.6,10,.6),'yellow',True)
box('Quay crane beam',(-16,9.8,12),(14,.5,.55),'yellow')
# A small service boat slung beneath the gantry, as in the port reference.
boat_path=os.path.join(ROOT,'assets/models/watercraft/boat_fishing.glb')
before=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=boat_path)
boat_objects=[o for o in bpy.data.objects if o not in before]
boat_meshes=[o for o in boat_objects if o.type=='MESH']
points=[o.matrix_world@Vector(c) for o in boat_meshes for c in o.bound_box]
lo=Vector(tuple(min(p[a] for p in points) for a in range(3)));hi=Vector(tuple(max(p[a] for p in points) for a in range(3)))
scale=6.2/max(hi.x-lo.x,hi.y-lo.y)
for o in boat_meshes:
    transform=o.matrix_world.copy()
    o.parent=None;o.matrix_world=transform
    for v in o.data.vertices:v.co=(transform@v.co-Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z)))*scale+Vector((-16,-12,1.1))
    o.matrix_world.identity()
for o in boat_objects:
    if o.type!='MESH':bpy.data.objects.remove(o,do_unlink=True)
for x in [-17.2,-14.8]:box('Boat sling',(x,2.1,12),(.12,2.1,.15),'steel')
for z in [-14,14]:box('Quay edge',(0,.08,z),(47,.16,.2),'yellow')
export('ifira_port')
clear();colliders=[]

# Temporary-name evening nakamal, three serving windows and sheltered benches.
box('Floor',(0,-.12,0),(15,.24,12),'concrete',True)
box('Service hut rear',(0,1.5,-5),(14,3,.16),'wood',True)
for x in [-7,7]:box('Hut side',(x,1.5,-3),(.16,3,4),'wood',True)
box('Serving counter',(0,.95,-.8),(13.8,.18,.65),'wood',True)
box('Front low wall',(0,.44,-1),(14,.88,.14),'cream',True)
box('Window lintel',(0,2.65,-1),(14,.65,.14),'wood',True)
for x in [-7,-2.35,2.35,7]:box('Serving post',(x,1.7,-1),(.16,1.9,.16),'wood',True)
for x in [-7,7]:
    for z in [0,5.6]:cylinder('Veranda post',(x,1.6,z),.10,3.2,'wood');colliders.append({'center':(x,1.6,z),'size':(.2,3.2,.2)})
for side in [-1,1]:
    o=box('Metal roof',(0,3.7,side*3.2),(15.5,.13,6.8),'roof');o.rotation_euler.x=side*.16
box('Ridge',(0,4.25,0),(15.7,.12,.18),'roof')
for x in [-4.9,4.9]:
    for z in [1.4,4.7]:
        box('Bench seat',(x,.47,z),(3.5,.10,.5),'wood',True)
        for dx in [-1.3,1.3]:box('Bench leg',(x+dx,.23,z),(.10,.46,.4),'wood')
    box('Long table',(x,.8,3.05),(3.4,.12,.8),'wood',True)
    for dx in [-1.2,1.2]:box('Table leg',(x+dx,.38,3.05),(.12,.76,.65),'wood')
for x in [-4.5,0,4.5]:
    bowl=cylinder('Coconut shell',(x,1.08,-.65),.17,.13,'wood')
    cylinder('Warm hanging lantern',(x,2.9,4.4),.13,.28,'lamp')
box('Temporary sign',(0,2.8,5.8),(8.3,.7,.07),'green')
lettering('EVENING NAKAMAL',(0,2.65,5.86),.38,'cream')
shutters=bpy.data.objects.new('ClosedShutters',None);bpy.context.collection.objects.link(shutters)
for x in [-4.7,0,4.7]:box('Closed serving shutter',(x,1.69,-.91),(4.45,1.4,.06),'roof',False,shutters)
export('evening_nakamal',(None,shutters))
if '--models-only' in __import__('sys').argv: raise SystemExit(0)
clear()

# Aerial hero: actual baked island height grid, ocean and instanced canopy.
data=json.load(open(os.path.join(ROOT,'tools/.cache/island-expansion/terrain.json')))
n=data['n'];heights=data['heights'];step=data['step'];minimum=data['min'];stride=2
world_span=(n-3)*step;render_scale=world_span/2880
ids=list(range(0,n,stride));verts=[];faces=[]
for z in ids:
    for x in ids:verts.append((minimum+x*step,-(minimum+z*step),heights[z*n+x]*1.7))
width=len(ids)
for z in range(width-1):
    for x in range(width-1):
        a=z*width+x;faces.append((a,a+width,a+width+1,a+1))
mesh=bpy.data.meshes.new('Efate actual height grid');mesh.from_pydata(verts,[],faces);mesh.update()
land=bpy.data.objects.new('Efate aerial terrain',mesh);bpy.context.collection.objects.link(land)
uv=mesh.uv_layers.new(name='Map')
for poly in mesh.polygons:
    poly.use_smooth=True
    for loop in poly.loop_indices:
        co=mesh.vertices[mesh.loops[loop].vertex_index].co;uv.data[loop].uv=((co.x+world_span/2)/world_span,(co.y+world_span/2)/world_span)
m=material('Photographic island terrain',(.45,.58,.28));p=m.node_tree.nodes.get('Principled BSDF');image=m.node_tree.nodes.new('ShaderNodeTexImage');image.image=bpy.data.images.load(os.path.join(ROOT,'assets/baked/terrain_macro.png'));m.node_tree.links.new(image.outputs['Color'],p.inputs['Base Color']);land.data.materials.append(m)
water=material('Clear Pacific',(.025,.25,.31),.23);p=water.node_tree.nodes.get('Principled BSDF');p.inputs['Metallic'].default_value=.12
noise=water.node_tree.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=260
bump=water.node_tree.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.16;bump.inputs['Distance'].default_value=.08;water.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);water.node_tree.links.new(bump.outputs['Normal'],p.inputs['Normal'])
bpy.ops.mesh.primitive_plane_add(size=12000*render_scale,location=(0,0,.04));bpy.context.object.name='Pacific Ocean';bpy.context.object.data.materials.append(water)
rng=random.Random(745)
canopies=[material('Canopy '+str(i),c) for i,c in enumerate([(.035,.105,.022),(.065,.16,.035),(.10,.21,.048)])]
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1);source=bpy.context.object;source.name='Canopy prototype'
for mat in canopies:source.data.materials.append(mat)
for poly in source.data.polygons:poly.material_index=rng.randrange(3);poly.use_smooth=True
for z in range(5,n-5,max(1,math.ceil(render_scale))):
    for x in range(5,n-5,max(1,math.ceil(render_scale))):
        h=heights[z*n+x]
        if h<4 or rng.random()<.18:continue
        obj=bpy.data.objects.new('Forest canopy',source.data);bpy.context.collection.objects.link(obj)
        obj.location=(minimum+x*step+rng.uniform(-4,4),-(minimum+z*step+rng.uniform(-4,4)),h*1.7+2)
        obj.scale=(rng.uniform(4,9),rng.uniform(4,9),rng.uniform(4,8))
bpy.data.objects.remove(source,do_unlink=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24
scene.render.resolution_x=1920;scene.render.resolution_y=1080;scene.render.resolution_percentage=100
scene.world.use_nodes=True;scene.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.48,.68,.83,1);scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.65
bpy.ops.object.light_add(type='SUN',location=(0,0,2000));sun=bpy.context.object;sun.rotation_euler=(math.radians(52),math.radians(-20),math.radians(-32));sun.data.energy=3.5;sun.data.angle=.08
bpy.ops.object.camera_add(location=Vector((-2250,-2700,2500))*render_scale);camera=bpy.context.object;direction=Vector((-150,100,40))*render_scale-camera.location;camera.rotation_euler=direction.to_track_quat('-Z','Y').to_euler();camera.data.clip_end=20000*render_scale;camera.data.lens=39;scene.camera=camera
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
os.makedirs(os.path.join(ROOT,'assets/menu'),exist_ok=True)
scene.render.filepath=os.path.join(ROOT,'assets/menu/efate_aerial.png')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ART,'efate_aerial.blend'))
bpy.ops.render.render(write_still=True)
print('ISLAND_EXPANSION_COMPLETE')
