"""Separate grounded salon planters and author the Elluk reference interior.
Exterior proportions are interpretation, not a measured survey.
"""
import bpy, os, json, math
from mathutils import Vector
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT=os.path.join(ROOT,'assets/models/island_refined')
def clear():
    for o in list(bpy.data.objects): bpy.data.objects.remove(o,do_unlink=True)
clear()
bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT,'assets/models/props/spa_furniture.glb'))
centers=[(-6.4,0,-5.5),(4.25,0,1.55),(-7.8,-.14,5.4),(-6.8,-.14,5.4),(-5.8,-.14,5.4)]
roots=[]
for i,(x,y,z) in enumerate(centers):
    o=bpy.data.objects.new('GroundedPlanter'+str(i),None);bpy.context.collection.objects.link(o)
    o.location=(x,-z,y);roots.append(o)
for obj in list(bpy.data.objects):
    if obj.type!='MESH' or not any(n in obj.name for n in ['SpaPlanterPots','SpaGreenFoliage']): continue
    groups=[[] for _ in centers]
    for poly in obj.data.polygons:
        c=obj.matrix_world@poly.center
        nearest=min(range(5),key=lambda i:(c.x-centers[i][0])**2+(c.y+centers[i][2])**2)
        groups[nearest].append(poly)
    for i,polys in enumerate(groups):
        verts=[];faces=[];mapping={}
        for poly in polys:
            face=[]
            for v in poly.vertices:
                if v not in mapping:
                    mapping[v]=len(verts);verts.append(obj.matrix_world@obj.data.vertices[v].co-roots[i].location)
                face.append(mapping[v])
            faces.append(face)
        mesh=bpy.data.meshes.new(obj.name+str(i));mesh.from_pydata(verts,[],faces);mesh.update()
        for mat in obj.data.materials: mesh.materials.append(mat)
        for target,source in zip(mesh.polygons,polys): target.material_index=source.material_index;target.use_smooth=source.use_smooth
        new=bpy.data.objects.new(obj.name+str(i),mesh);bpy.context.collection.objects.link(new);new.parent=roots[i]
    bpy.data.objects.remove(obj,do_unlink=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'spa_grounded.glb'),export_format='GLB')
clear()
colliders=[]
def mat(name,color,rough=.7):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough
    return m
cream=mat('Cream plaster',(.85,.83,.75));white=mat('White linen',(.92,.91,.86));black=mat('Charcoal tile',(.035,.045,.043),.35)
wood=mat('Dark teak',(.14,.075,.035));purple=mat('Purple table runner',(.28,.08,.32));gold=mat('Gold frames',(.63,.44,.13),.3)
steel=mat('Chrome',(.5,.54,.55),.22);green=mat('Leaves',(.12,.28,.10));roof=mat('Corrugated roof',(.26,.31,.28));red=mat('Thai flag red',(.65,.055,.06));blue=mat('Thai flag blue',(.025,.04,.2))
def box(name,at,size,m,solid=False):
    x,y,z=at;w,h,d=size;bpy.ops.mesh.primitive_cube_add(size=1,location=(x,-z,y));o=bpy.context.object;o.name=name;o.dimensions=(w,d,h);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
    if solid: colliders.append({'center':at,'size':size})
    return o
def cylinder(name,at,r,h,m):
    x,y,z=at;bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=h,location=(x,-z,y));o=bpy.context.object;o.name=name;o.data.materials.append(m);return o
# Walkable open dining room; checker floor, bar and furnishings follow the verified photo.
box('Foundation',(0,-.4,0),(16,.8,12),cream,True)
for x in range(20):
    for z in range(15): box('Checker tile',(-7.6+x*.8,.015,-5.6+z*.8),(.796,.03,.796),white if (x+z)%2 else black)
box('Back wall',(0,1.7,-6),(16,3.4,.18),cream,True)
for x in [-8,8]:
    box('Window sill',(x,.4,0),(.18,.8,12),cream,True)
    for z in [-5.9,-2,2,5.9]: box('Window column',(x,1.7,z),(.22,3.4,.22),cream,True)
    box('Window lintel',(x,3.1,0),(.22,.6,12),cream,True)
# Front elevation rebuilt from the three user supplied March 2025 photographs.
# Raised cream weatherboard bungalow, paired screened/louvre windows and central door.
for x in [-4.55,4.55]: box('Front wall',(x,1.55,6),(6.9,3.1,.16),cream,True)
for y in [i*.16 for i in range(20)]:
    for x in [-4.55,4.55]: box('Weatherboard seam',(x,y,6.095),(6.9,.014,.022),white)
for x in [-6.8,-5.25,-3.65,-2.05,2.05,3.65,5.25,6.8]:
    box('Window dark screen',(x,1.72,6.105),(1.18,1.55,.035),black)
    for xx in [-.63,.63]:box('Window jamb',(x+xx,1.72,6.15),(.075,1.7,.07),white)
    for yy in [.9,2.55]:box('Window rail',(x,yy,6.15),(1.33,.075,.07),white)
    if abs(x)>4:
        for yy in range(8):box('Louvre blade',(x,1.02+yy*.19,6.16),(1.15,.145,.045),cream)
    else:
        for k in range(-5,6):
            for sign in [-1,1]:
                # Fine security mesh clipped inside each glazed panel.
                y0=max(.98,1.72+k*.22-.54);y1=min(2.46,1.72+k*.22+.54)
                if y1<=y0:continue
                xx0=x+sign*(y0-1.72-k*.22)*.68;xx1=x+sign*(y1-1.72-k*.22)*.68
                dx=xx1-xx0;dy=y1-y0;o=box('Window diamond grille',((xx0+xx1)/2,(y0+y1)/2,6.18),(.012,math.hypot(dx,dy),.012),steel);o.rotation_euler.y=-math.atan2(dx,dy)
for x in [-1.04,1.04]:box('Door jamb',(x,1.3,6.02),(.12,2.6,.22),white,True)
box('Door lintel',(0,2.66,6.02),(2.2,.18,.22),white,True)
# Open door leaves retain the photographed white framing and horizontal glass panes.
for side in [-1,1]:
    x=side*.98
    for zz in [6.1,5.22]:box('Open door stile',(x,1.25,zz),(.065,2.5,.09),white,True)
    for yy in [0.06,.52,1.15,1.82,2.43]:box('Open door rail',(x,yy,5.66),(.065,.09,.96),white)
box('Entry landing',(0,-.05,6.9),(2.35,.12,1.8),cream,True)
for x in [-1.15,1.15]:
    box('Entrance post',(x,1.65,7.65),(.16,3.3,.16),white,True)
    for z in [6.2,6.48,6.76,7.04,7.32,7.6]:box('Landing baluster',(x,.48,z),(.04,.92,.04),white)
    box('Landing handrail',(x,.98,6.9),(.11,.1,1.9),wood,True)
# Shallow front gable with exposed cream rafters, as photographed.
for side in [-1,1]:
    o=box('Porch roof',(side*.78,3.61,6.9),(1.66,.10,2.45),roof);o.rotation_euler.y=side*math.radians(12)
    for z in [5.85,6.35,6.85,7.35,7.95]:
        o=box('Exposed rafter',(side*.78,3.53,z),(1.68,.11,.10),white);o.rotation_euler.y=side*math.radians(12)
box('Gable tie',(0,3.27,7.99),(3.2,.14,.10),white)
box('Gable kingpost',(0,3.61,7.99),(.12,.58,.12),white)
# Orange elephant sign is geometry with editable type; no screenshot textures.
orange=mat('Sign orange',(.95,.30,.008));yellow=mat('Sign yellow',(.93,.83,.07));silver=mat('Elephant silver',(.59,.73,.77))
serif='C:/Windows/Fonts/times.ttf';sans='C:/Windows/Fonts/arial.ttf'
fonts={f:bpy.data.fonts.load(f) for f in [serif,sans] if os.path.exists(f)}
def text(value,x,y,z,size,m,font=sans):
    curve=bpy.data.curves.new('Sign lettering','FONT');curve.body=value;curve.size=size;curve.align_x='CENTER';curve.extrude=.0005
    if font in fonts:curve.font=fonts[font]
    o=bpy.data.objects.new(value,curve);bpy.context.collection.objects.link(o);o.location=(x,-z,y);o.rotation_euler.x=math.pi/2;curve.materials.append(m)
    bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False)
    return o
def line(name,points,r,m):
    c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=1;spline=c.splines.new('POLY');spline.points.add(len(points)-1)
    for p,v in zip(spline.points,points):p.co=(v[0],-v[2],v[1],1)
    o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);c.materials.append(m);bpy.context.view_layer.objects.active=o;o.select_set(True);bpy.ops.object.convert(target='MESH');o.select_set(False)
def sign(cx,cy,cz,w,h):
    box('Orange sign',(cx,cy,cz),(w,h,.055),orange)
    text('PAD THAI',cx+w*.13,cy+h*.16,cz+.032,h*.31,yellow,serif)
    text('RESTAURANT@ ELLUK',cx+w*.15,cy-h*.015,cz+.034,h*.075,white)
    text('7799994',cx+w*.28,cy-h*.31,cz+.034,h*.14,silver)
    text('THAI GALLERY',cx+w*.055,cy-h*.19,cz+.034,h*.065,white,serif)
    text('VANUATU',cx+w*.055,cy-h*.31,cz+.034,h*.065,white,serif)
    outline=[(-.15,.44),(-.27,.46),(-.33,.40),(-.35,.30),(-.32,.17),(-.27,-.01),(-.27,-.36),(-.13,-.36),(-.13,-.18),(-.08,-.14),(-.02,-.17),(.00,-.36),(.14,-.36),(.15,-.12),(.24,-.09),(.12,.00),(.04,.10),(-.10,.13),(-.23,.12),(-.26,.06),(-.22,-.02),(-.13,-.04),(-.05,-.01),(-.02,.09),(-.05,.23),(-.21,.27),(-.28,.30),(-.27,.37),(-.15,.39)]
    line('Elephant outline',[(cx-w*.30+u*h,cy+v*h,cz+.04) for u,v in outline],h*.008,silver)
    cylinder('Sign bolt',(cx-w*.46,cy-h*.43,cz+.04),.012,.02,steel)
sign(0,2.78,8.035,2.65,.90)
# Independent roadside panel can be grounded to its own terrain height in Godot.
before=set(bpy.data.objects)
sign(0,1.75,0,3.3,1.42)
for x in [-1.3,1.3]:box('Road sign post',(x,.85,-.05),(.075,2.8,.075),steel)
yard=bpy.data.objects.new('RoadsideSign',None);bpy.context.collection.objects.link(yard)
for obj in set(bpy.data.objects)-before:
    if obj!=yard:obj.parent=yard
yard.location=(-4,-12,0)
box('Ceiling',(0,3.42,0),(16.7,.16,12.7),white)
box('Front white fascia',(0,3.44,6.4),(16.8,.22,.12),white)
for side in [-1,1]:
    o=box('Roof slope',(side*4.3,4.12,0),(8.9,.12,13.2),roof);o.rotation_euler.y=side*math.radians(9)
box('Bar panel',(0,.55,-4.8),(5.6,1.1,.85),white,True)
box('Dark bar top',(0,1.14,-4.8),(5.9,.1,1.05),black,True)
for x in [-2.2,0,2.2]:
    cylinder('Stool base',(x,.06,-3.6),.24,.12,steel);cylinder('Stool stem',(x,.44,-3.6),.045,.75,steel);cylinder('Stool cushion',(x,.85,-3.6),.25,.12,black)
    colliders.append({'center':(x,.44,-3.6),'size':(.48,.88,.48)})
for y in [1.45,2.05,2.65]:
    box('Bottle shelf',(0,y,-5.75),(5.8,.07,.35),wood)
    for j in range(13): cylinder('Bottle',(-2.5+j*.4,y+.16,-5.72),.055,.25,green if j%2 else gold)
for x,z in [(-5,-2),(-5,1.8),(-2,2.2),(2,2.2),(5,1.8),(5,-2)]:
    box('Dining table',(x,.76,z),(1.55,.1,1.3),wood,True)
    box('White tablecloth',(x,.825,z),(1.65,.025,1.4),white)
    box('Purple runner',(x,.842,z),(.42,.012,1.42),purple)
    for sx in [-.62,.62]:
        for sz in [-.47,.47]: box('Table leg',(x+sx,.36,z+sz),(.065,.72,.065),wood)
    for dz in [-1,1]:
        box('Chair seat',(x,.47,z+dz),(.55,.12,.52),white,True)
        box('Chair back',(x,.83,z+dz*1.2),(.55,.7,.10),white,True)
        for dx in [-.21,.21]:
            for zz in [-.2,.2]:box('Chair leg',(x+dx,.23,z+dz+zz),(.055,.46,.055),wood)
for x,z in [(-4,0),(4,0),(0,-2)]:
    cylinder('Fan rod',(x,3.07,z),.035,.5,steel);cylinder('Fan hub',(x,2.81,z),.13,.12,white)
    for i in range(3):
        angle=i*math.tau/3;o=box('Fan blade',(x+math.cos(angle)*.4,2.8,z+math.sin(angle)*.4),(.8,.025,.16),white);o.rotation_euler.z=-angle
for i,m in enumerate([red,white,blue,blue,white,red]): box('Thai flag',(-5,2.3-i*.1,-5.86),(1,.1,.025),m)
for x in [-6,6]:
    box('Gold picture frame',(x,2,-5.85),(1.05,.8,.06),gold);box('Picture',(x,2,-5.81),(.9,.65,.025),purple)
os.makedirs(os.path.join(ROOT,'art/blender'),exist_ok=True)
# One mesh per material keeps the detailed room affordable on mobile.
for group in [None,yard]:
    for m in list(bpy.data.materials):
        objects=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==group and o.data.materials and o.data.materials[0]==m]
        if not objects:continue
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();objects[0].name=m.name
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art/blender/elluk_restaurant.blend'))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'elluk_restaurant.glb'),export_format='GLB')
with open(os.path.join(OUT,'elluk_colliders.json'),'w') as f:json.dump(colliders,f)
print('ELLUK_COMPLETE',len(colliders))
