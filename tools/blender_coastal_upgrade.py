"""Original mobile-friendly Blender landmark templates and architectural detail kit.
Sites use OSM coordinates; these are interpreted structures, not surveyed replicas.
Run Blender --background --python tools/blender_coastal_upgrade.py.
"""
import bpy,math,json,os,random
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT=os.path.join(ROOT,'assets/models/coastal_detail');os.makedirs(OUT,exist_ok=True)
ART=os.path.join(ROOT,'art/blender');os.makedirs(ART,exist_ok=True)
def clear():
    for o in list(bpy.data.objects):bpy.data.objects.remove(o,do_unlink=True)
clear()
def material(name,color,rough=.8,metal=0):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
    return m
mats={k:material(k,c) for k,c in {'plaster':(.75,.73,.65),'roof':(.22,.31,.29),'wood':(.31,.20,.11),'concrete':(.47,.46,.42),'steel':(.10,.13,.12),'glass':(.14,.27,.30),'teal':(.06,.31,.27),'sandstone':(.56,.49,.36),'water':(.05,.43,.39),'green':(.12,.30,.08),'red':(.57,.16,.09)}.items()}
colliders=[]
def box(name,at,size,key,solid=False,bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=(at[0],-at[2],at[1]));o=bpy.context.object;o.name=name;o.dimensions=(size[0],size[2],size[1]);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[key])
    if bevel:
        b=o.modifiers.new('Rounded manufactured edges','BEVEL');b.width=bevel;b.segments=2;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=b.name)
        o.modifiers.new('Weighted surface normals','WEIGHTED_NORMAL')
    if solid:colliders.append({'center':at,'size':size})
    return o
def cyl(name,at,r,h,key):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=h,location=(at[0],-at[2],at[1]));o=bpy.context.object;o.name=name;o.data.materials.append(mats[key]);return o
def beam(name,a,b,r,key):
    aa=Vector((a[0],-a[2],a[1]));bb=Vector((b[0],-b[2],b[1]));d=bb-aa
    bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=d.length,location=(aa+bb)/2);o=bpy.context.object;o.name=name;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();o.data.materials.append(mats[key]);return o
def roof(w,d,h,key='roof'):
    rise=1.6
    for side in [-1,1]:
        o=box('Pitched roof',(0,h+rise/2,side*d/4),(w+.7,.09,math.hypot(d/2,rise)+.45),key)
        o.rotation_euler.x=side*math.atan2(rise,d/2)
        for x in range(-int(w/2*4),int(w/2*4)+1):
            beam('Standing seam',(x/4,h+rise,0),(x/4,h-.03,side*(d/2+.25)),.017,key)
    beam('Roof ridge',(-w/2-.4,h+rise+.03,0),(w/2+.4,h+rise+.03,0),.07,key)
def hall(w,d,kind):
    box('Slab',(0,-.1,0),(w,.2,d),'concrete',True,.03)
    box('Rear wall',(0,1.6,-d/2),(w,3.2,.15),'plaster',True)
    for x in [-w/2,w/2]:box('End wall',(x,1.6,0),(.15,3.2,d),'plaster',True)
    if kind!='market':
        for x in [-w/4-1,w/4+1]:box('Front wall',(x,1.6,d/2),(w/2-2,3.2,.15),'plaster',True)
        box('Door lintel',(0,2.95,d/2),(4,.5,.15),'plaster',True)
    for x in range(-int(w/2)+2,int(w/2),4):
        if kind=='market' or abs(x)<2.1:continue
        box('Window',(x,1.8,d/2+.09),(2.1,1.25,.05),'glass')
        for xx in [-1.1,1.1]:box('Window trim',(x+xx,1.8,d/2+.14),(.07,1.4,.06),'wood')
        box('Sill',(x,1.13,d/2+.17),(2.3,.08,.19),'wood')
    roof(w,d,3.2)
    for x in [-w/2+.4,w/2-.4]:
        beam('Rainwater pipe',(x,3.15,d/2+.3),(x,.05,d/2+.3),.05,'steel')
    box('Welcome fascia',(0,2.65,d/2+.15),(min(w-1,10),.45,.09),'teal')
    if kind=='market':
        for x in [-w/2,-w/4,w/4,w/2]:box('Front support column',(x,1.6,d/2),(.18,3.2,.18),'wood',True)
        for x in [-5,0,5]:
            box('Market counter',(x,.8,0),(3,.15,1.3),'wood',True,.02)
            for xx in [-1.3,1.3]:box('Counter leg',(x+xx,.4,0),(.12,.8,1),'wood')
            for i in range(6):cyl('Produce basket',(x-1+i*.4,.98,0),.17,.2,'sandstone')
    if kind=='museum':
        for x in [-3,3]:
            cyl('Interpretive slit drum',(x,1.2,-1),.3,2.4,'wood')
            box('Drum slit',(x,1.3,-.69),(.055,1.1,.025),'steel')
    if kind=='hospital':
        box('Covered reception canopy',(0,2.5,d/2+1.8),(8,.14,3.6),'teal')
        for x in [-3.6,3.6]:box('Canopy post',(x,1.25,d/2+3.4),(.14,2.5,.14),'steel',True)
    if kind=='airport':
        box('Control room',(w/2-3,5,-d/2+2),(4,4,4),'plaster',True)
        box('Tower glazing',(w/2-3,6.2,-d/2+2.1),(4.12,1.2,4.12),'glass')
        box('Tower roof',(w/2-3,7.05,-d/2+2),(4.6,.15,4.6),'roof')
def rocks(kind):
    rng=random.Random(72)
    if kind in ['lagoon','waterfall','river']:
        box('Pool bottom',(0,-.16,0),(14,.3,9),'sandstone',True)
        bpy.ops.mesh.primitive_circle_add(vertices=48,radius=1,fill_type='NGON',location=(0,0,.18));pool=bpy.context.object;pool.name='Natural clear pool';pool.scale=(6.7,3.9,1);pool.data.materials.append(mats['water'])
    for i in range(28):
        a=i/28*math.tau;x=7.2*math.cos(a);z=4.8*math.sin(a)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=(x,-z,.4));o=bpy.context.object;o.name='Weathered limestone';o.scale=(rng.uniform(.6,1.4),rng.uniform(.5,1.0),rng.uniform(.6,1.1));o.data.materials.append(mats['sandstone'])
        for p in o.data.polygons:p.use_smooth=True
    if kind=='waterfall':
        for i in range(16):
            x=rng.uniform(-5,5);z=rng.uniform(-6,-3.9);h=rng.uniform(1.4,3.3)
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=(x,-z,h/2));o=bpy.context.object;o.name='Travertine cliff';o.scale=(rng.uniform(.7,1.7),rng.uniform(.7,1.4),h);o.data.materials.append(mats['sandstone'])
            for p in o.data.polygons:p.use_smooth=True
        for x,z,h in [(-1.8,-3.9,3.8),(.5,-4.1,4.5),(2,-3.8,3.3)]:
            box('Falling water veil',(x,h/2,z),(rng.uniform(.45,.9),h,.025),'water')
    if kind=='river':
        box('Timber footbridge',(0,.22,0),(2.4,.15,11),'wood',True)
        # Solid sloping approaches meet the bridge above the pool's lip.
        for side in [-1,1]:
            top=[(-1.2,-5.1*side,.30),(1.2,-5.1*side,.30),(-1.2,-5.9*side,.30),(1.2,-5.9*side,.30),(-1.2,-7.5*side,0),(1.2,-7.5*side,0)]
            vs=top+[(x,y,-.15) for x,y,z in top]
            faces=[(0,2,3,1),(2,4,5,3),(6,7,9,8),(8,9,11,10),(0,1,7,6),(4,10,11,5),(0,6,8,2),(2,8,10,4),(1,3,9,7),(3,5,11,9)]
            data=bpy.data.meshes.new('Bridge approach');data.from_pydata(vs,[],faces);data.update();o=bpy.data.objects.new('Bridge approach',data);bpy.context.collection.objects.link(o);o.data.materials.append(mats['wood'])
            colliders.append({'points':[[x,z,-y] for x,y,z in vs]})
        for x in [-1.15,1.15]:
            beam('Bridge handrail',(x,1.6,-5),(x,1.6,5),.045,'wood')
            for z in [-4,0,4]:beam('Bridge post',(x,.6,z),(x,1.6,z),.05,'wood')
    if kind=='cave':
        for x in [-3,3]:box('Cave rock pier',(x,1.5,0),(2,3,4),'sandstone',True,.5)
        box('Rock arch',(0,3.25,0),(8,1.5,4),'sandstone',True,.5)
        box('Dark rear',(0,1.5,-2),(6,3,.3),'steel',True)
def export(kind):
    for m in list(bpy.data.materials):
        objects=[o for o in bpy.data.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==m]
        if not objects:continue
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1:bpy.ops.object.join()
        objects[0].name=m.name
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ART,'coastal_'+kind+'.blend'))
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,kind+'.glb'),export_format='GLB',export_apply=True)
    json.dump(colliders,open(os.path.join(OUT,kind+'_collision.json'),'w'))
for kind in ['market','museum','hospital','airport','post','culture','beach','underwater_post','waterfall','lagoon','river','cave']:
    clear();colliders=[]
    if kind in ['market','museum','hospital','airport','post','culture']:hall(28 if kind=='airport' else 18 if kind in ['market','hospital'] else 12,10 if kind in ['airport','hospital','market'] else 8,kind)
    elif kind in ['waterfall','lagoon','river','cave']:rocks(kind)
    else:
        box('Timber landing',(0,-.08,0),(7,.16,5),'wood',True)
        if kind=='beach':
            for x in [-3,3]:
                for z in [-2,2]:box('Shelter post',(x,1.3,z),(.12,2.6,.12),'wood',True)
            roof(7,5,2.6)
            box('Picnic table',(0,.8,0),(3,.12,1),'wood',True)
        else:
            cyl('Underwater post box',(0,.8,0),.38,1.6,'red')
    export(kind)
# Architectural kit: each named root can be instantiated independently in Godot.
clear();colliders=[]
for kind in ['planter','bench','lantern','ac_unit','gutter','drain','bollard']:
    parent=bpy.data.objects.new(kind,None);bpy.context.collection.objects.link(parent)
    before=set(bpy.data.objects)
    if kind=='planter':
        cyl('Terracotta pot',(0,.35,0),.36,.7,'sandstone')
        cyl('Pot rim',(0,.68,0),.39,.1,'sandstone')
        cyl('Soil',(0,.71,0),.31,.025,'wood')
        for i in range(9):
            a=i/9*math.tau;beam('Tropical foliage',(0,.7,0),(.45*math.cos(a),1.2+(i%3)*.2,.45*math.sin(a)),.035,'green')
    if kind=='bench':
        for z in [-.17,0,.17]:box('Seat slat',(0,.45,z),(1.8,.07,.12),'wood',False,.015)
        for x in [-.7,.7]:box('Cast leg',(x,.21,0),(.09,.42,.5),'steel')
        for y in [.75,.95]:box('Back slat',(0,y,-.25),(1.8,.14,.06),'wood',False,.015)
    if kind=='lantern':
        box('Mount plate',(0,.05,-.05),(.14,.3,.05),'steel')
        box('Frosted glass',(0,0,.1),(.2,.26,.17),'glass',False,.02)
        for y in [-.15,.15]:box('Lantern cap',(0,y,.1),(.26,.05,.23),'steel',False,.015)
    if kind=='ac_unit':
        box('Outdoor AC casing',(0,0,0),(1,.7,.4),'plaster',False,.04)
        fan=cyl('Fan grille',(0,0,.22),.26,.025,'steel');fan.rotation_euler.x=math.pi/2
        for x in [-.4,.4]:box('Wall bracket',(x,-.42,0),(.07,.15,.5),'steel')
        for i in range(9):box('Vent slat',(.35,-.22+i*.055,.21),(.15,.025,.015),'steel')
    if kind=='gutter':
        beam('Gutter',(-1,0,0),(1,0,0),.065,'steel')
        beam('Downspout',(1,0,0),(1,-2.7,0),.045,'steel')
        beam('Outlet',(1,-2.7,0),(1,-2.7,.2),.045,'steel')
    if kind=='drain':
        box('Drain frame',(0,0,0),(1,.045,.4),'steel')
        for i in range(12):box('Drain slot',(-.44+i*.08,.03,0),(.03,.025,.32),'concrete')
    if kind=='bollard':
        cyl('Bollard',(0,.45,0),.1,.9,'steel');cyl('Reflective band',(0,.7,0),.105,.08,'plaster')
    for o in set(bpy.data.objects)-before:o.parent=parent
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ART,'coastal_detail_kit.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'detail_kit.glb'),export_format='GLB',export_apply=True)
print('COASTAL_BLENDER_UPGRADE_COMPLETE')
