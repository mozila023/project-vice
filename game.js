// MAHA COMBO (มหาคอมโบ)
// ภาพทั้งหมดในโฟลเดอร์ assets/ วาดด้วย ChatGPT แล้วตัดเป็นเฟรม
(()=>{
const W=960,H=540,GY=470;
const cv=document.getElementById('c'),ctx=cv.getContext('2d');
const stageEl=document.getElementById('stage');
let dpr=1;
function resize(){dpr=Math.min(2,window.devicePixelRatio||1);const s=Math.min(innerWidth/W,innerHeight/H);
  const w=Math.floor(W*s),h=Math.floor(H*s);cv.style.width=w+'px';cv.style.height=h+'px';stageEl.style.width=w+'px';stageEl.style.height=h+'px';
  cv.width=W*dpr;cv.height=H*dpr;}
addEventListener('resize',resize);resize();
const isTouch=('ontouchstart' in window)||navigator.maxTouchPoints>0;
if(isTouch)document.getElementById('touch').style.display='block';
// วางปุ่มมือถือตามขนาดจอจริง: ใช้ขอบดำข้างจอ (จอมือถือกว้างกว่า 16:9) ให้มากที่สุด ปุ่มจะได้ไม่บังฉาก
function layoutTouch(){if(!isTouch)return;const vw=innerWidth,vh=innerHeight,u=Math.max(46,Math.min(84,vh*.17)),side=(vw-parseFloat(cv.style.width||vw))/2;
  const pad=Math.max(10,Math.min(side-u*.55,24)),B=Math.max(10,vh*.04);
  const put=(k,cx,cy,sz,fs)=>{const el=document.querySelector('#touch [data-k="'+k+'"]');if(!el)return;cx=Math.max(sz/2+4,Math.min(vw-sz/2-4,cx));cy=Math.max(sz/2+4,Math.min(vh-sz/2-4,cy));el.style.width=el.style.height=sz+'px';el.style.left=(cx-sz/2)+'px';el.style.top=(cy-sz/2)+'px';el.style.right=el.style.bottom='auto';el.style.fontSize=(fs||sz*.38)+'px';};
  // ซ้าย: เดิน
  const lx=pad+u*.6,ly=vh-B-u*.6;put('left',lx,ly,u*1.1);put('right',lx+u*1.3,ly,u*1.1);
  // ขวา: ฟันใหญ่ตรงมุม ปุ่มอื่นเรียงเป็นวงโค้งรอบนิ้วโป้ง
  const ax=vw-pad-u*.72,ay=vh-B-u*.72,R=u*1.42;put('atk',ax,ay,u*1.45);
  const arc=(k,deg,r,sz)=>{const a=deg*Math.PI/180;put(k,ax+Math.cos(a)*r,ay-Math.sin(a)*r,sz);};
  arc('jump',180,R,u*.92);arc('dodge',138,R,u*.86);arc('core',97,R,u*.86);arc('skill',80,R*1.85,u*.84);
  const cw=parseFloat(cv.style.width||vw),ch=parseFloat(cv.style.height||vh),cl=(vw-cw)/2,ct=(vh-ch)/2,sc=cw/W;
  if(side>=u*.8)put('edit',vw-side/2,ct+u*.45,u*.7);else put('edit',cl+700*sc,ct+26*sc+u*.2,u*.62);
  const sk=document.getElementById('tutSkip');if(sk){sk.style.position='fixed';sk.style.right=(pad+u*.8)+'px';sk.style.top=(Math.max(10,vh*.03)+u*.12)+'px';}}
addEventListener('resize',()=>setTimeout(layoutTouch,50));setTimeout(layoutTouch,0);
// เกจบนปุ่มมือถือ (Core / คอมโบ / คูลดาวน์หลบ)
const tbs={};function touchGauges(){if(!isTouch)return;const q=k=>tbs[k]||(tbs[k]=document.querySelector('#touch [data-k="'+k+'"]'));
  const set=(k,p,ready,col)=>{const el=q(k);if(!el)return;el.classList.add('g');const v=Math.round(p*100);if(el._p!==v){el._p=v;el.style.setProperty('--p',v);}el.classList.toggle('ready',!!ready);if(col&&el._c!==col){el._c=col;el.style.setProperty('--c',col);}};
  const inStage=scene==='stage'&&state==='play';
  set('core',P.core/100,P.core>=100&&inStage,'#ffe066');set('skill',energy/100,energy>=100&&inStage&&!run&&!finale,'#8fb0ff');set('dodge',1-P.dodgeCD/.5,false,'#9fd8ff');
  for(const k of ['core','skill','dodge'])q(k)&&q(k).classList.toggle('hide',scene==='town');
  const ab=q('atk');if(ab){const cnt=eeT>0&&!P.cnt;if(ab._e!==cnt){ab._e=cnt;ab.style.boxShadow=cnt?'0 0 18px 6px #c9a8ff':'';}}}

// ================= สกิล =================
const SK={
 slash:{name:'ฟันรัว',dur:1.2,col:'#9ef',desc:'ฟันข้างหน้ารัว 10 ครั้ง'},
 upper:{name:'ฟันเสย',dur:1.0,col:'#ffd76a',desc:'ฟันศัตรูลอยขึ้นฟ้า'},
 dash:{name:'ดาบพุ่ง',dur:0.9,col:'#8fd',desc:'พุ่งทะลุแถวศัตรู'},
 slam:{name:'ฟาดลงพื้น',dur:1.3,col:'#ff9a5c',desc:'กระโดดทุบ ตัวที่ลอยโดนแรง x2'},
 spin:{name:'พายุดาบ',dur:2.0,col:'#c9f',desc:'หมุนฟันรอบตัว'},
 wave:{name:'คลื่นดาบ',dur:1.5,col:'#7cf',desc:'ปล่อยคลื่นดาบพุ่งไปข้างหน้า'},
 naga:{name:'นาคราช',dur:2.0,col:'#ffb347',desc:'พญานาคไฟพุ่งทะลวงแถว'},
 rain:{name:'ฝนดาบ',dur:2.5,col:'#bdf',desc:'ดาบตกจากฟ้าทั่วจอ'},
 chakra:{name:'จักรนารายณ์',dur:2.2,col:'#ffe066',desc:'ขว้างจักรออกไปแล้ววนกลับ'},
 thunder:{name:'สายฟ้าฟาด',dur:1.8,col:'#fff27a',desc:'ฟ้าผ่าศัตรูใกล้ตัว'},
 fire:{name:'ลมหายใจไฟ',dur:2.0,col:'#ff7a3d',desc:'พ่นไฟจากดาบ เผาข้างหน้า'},
 clone:{name:'แยกเงา',dur:2.5,col:'#b18cff',desc:'เงา 4 ร่างวาร์ปไปฟันทั่วจอ'},
 pillar:{name:'เสาแสง',dur:2.2,col:'#fffbe0',desc:'เสาแสงผุดจากพื้นเรียงแถว'},
 thousand:{name:'พันดาบ',dur:3.0,col:'#ff6ad5',desc:'ฟันรัวทุกตัวรอบๆ'},
 lotus:{name:'พายุบัว',dur:3.0,col:'#ff8fc8',desc:'กลีบบัวหมุนบาดรอบตัว'},
 vortex:{name:'หลุมดำ',dur:2.4,col:'#9a6bff',desc:'ดูดศัตรูมารวมแล้วระเบิด'},
 xslash:{name:'ฟันกากบาท',dur:1.6,col:'#ffffff',desc:'พุ่งทะลุแล้วระเบิดเป็นรูป X'},
 giant:{name:'ดาบเทวะ',dur:2.0,col:'#fff1a8',desc:'ดาบยักษ์ร่วงจากฟ้า'},
 // หมอผี
 m_orb:{name:'ลูกไฟวิญญาณ',dur:1.5,col:'#7ad7ff',desc:'ยิงไฟผีติดตามศัตรู'},
 m_bell:{name:'กระดิ่งเรียกวิญญาณ',dur:1.8,col:'#9fe8ff',desc:'คลื่นเสียงกระดิ่ง ทำศัตรูมึนงง'},
 m_tal:{name:'ยันต์ระเบิด',dur:1.6,col:'#ffd76a',desc:'ปาผ้ายันต์ติดตัวศัตรูแล้วระเบิด'},
 m_skull:{name:'กะโหลกบิน',dur:2.0,col:'#c08cff',desc:'กะโหลกผีบินไล่กัด'},
 m_hand:{name:'มือผีโผล่',dur:2.0,col:'#8a6aff',desc:'มือผีโผล่จากดินจับโยน'},
 m_summon:{name:'เรียกผีพราย',dur:2.6,col:'#7affd9',desc:'เรียกผี 3 ตนช่วยรุม'},
 m_curse:{name:'คำสาปตรึง',dur:2.2,col:'#b98cff',desc:'สาปศัตรูให้ขยับไม่ได้ แล้วระเบิด'},
 m_drain:{name:'ดูดวิญญาณ',dur:2.2,col:'#7dff9a',desc:'ดูดพลังชีวิตศัตรูมาเป็นของเรา'},
 m_ritual:{name:'พิธีกรรมมรณะ',dur:2.6,col:'#ff6ad5',desc:'วงยันต์ยักษ์บนพื้น แล้วระเบิดเสาไฟผี'},
 // นักธนู
 a_rapid:{name:'ยิงรัว',dur:1.2,col:'#ffe08a',desc:'ยิงธนูรัวไปข้างหน้า'},
 a_fan:{name:'ธนูกระจาย',dur:1.4,col:'#ffd76a',desc:'ยิงทีละ 7 ดอกเป็นรูปพัด'},
 a_pierce:{name:'ธนูทะลวง',dur:1.4,col:'#7dff9a',desc:'ศรพลังทะลุทั้งแถว'},
 a_bomb:{name:'ธนูระเบิด',dur:1.8,col:'#ff9a3d',desc:'ยิงโค้ง ตกแล้วระเบิด'},
 a_leap:{name:'ยิงกลางอากาศ',dur:1.6,col:'#9ef',desc:'กระโดดลอยแล้วยิงกดลงมา'},
 a_rain:{name:'ฝนธนู',dur:2.2,col:'#bdf',desc:'ธนูตกจากฟ้าทั่วจอ'},
 a_vine:{name:'ธนูเถาวัลย์',dur:2.0,col:'#5fdc6a',desc:'เถาวัลย์ผุดรัดศัตรูให้อยู่กับที่'},
 a_phoenix:{name:'ศรหงส์ทอง',dur:2.0,col:'#ffb347',desc:'ศรไฟรูปหงส์พุ่งทะลวง'},
 a_meteor:{name:'ศรเทวะ',dur:2.0,col:'#fff1a8',desc:'ศรยักษ์ร่วงจากฟ้า'},
 // สกิลเพิ่มใหม่ (ไอคอนยืมของเดิมแล้วเปลี่ยนสี)
 moon:{name:'ฟันจันทร์เสี้ยว',dur:1.4,col:'#cfe6ff',desc:'ปล่อยคลื่นจันทร์เสี้ยวทะลุทั้งแถว',ic:'ic_wave',hue:180},
 blink:{name:'เงาพริบตา',dur:1.6,col:'#e6d8ff',desc:'วาร์ปฟันศัตรูทีละตัวรอบจอ',ic:'ic_clone',hue:60},
 quake:{name:'ปฐพีแยก',dur:1.8,col:'#ffb37a',desc:'แผ่นดินแยกพุ่งไปข้างหน้า',ic:'ic_slam',hue:200},
 tornado:{name:'ทอร์นาโดดาบ',dur:2.2,col:'#b8f5c8',desc:'พายุดาบเคลื่อนที่ ดูดศัตรูเข้ามาบด',ic:'ic_spin',hue:90},
 meteor:{name:'ดาวตกพันดวง',dur:2.2,col:'#ff9a3d',desc:'ลูกไฟตกใส่ศัตรูแล้วระเบิด',ic:'ic_rain',hue:-40},
 garuda:{name:'ครุฑพิโรธ',dur:2.0,col:'#ffd76a',desc:'พญาครุฑทองโฉบกวาดทั้งจอ',ic:'ic_a_phoenix',hue:20},
 m_fire:{name:'ไฟนรกวน',dur:2.0,col:'#7ad7ff',desc:'เสาไฟผีผุดเป็นวงรอบตัว',ic:'ic_fire',hue:180},
 m_chain:{name:'สายฟ้าโซ่ผี',dur:1.8,col:'#9fe8ff',desc:'สายฟ้ากระโดดต่อกันหลายตัว',ic:'ic_thunder',hue:160},
 m_mirror:{name:'ร่างแยกหมอผี',dur:2.2,col:'#b98cff',desc:'เงาร่างแยก 2 ตนช่วยยิงไฟผี',ic:'ic_clone',hue:200},
 m_rain:{name:'ฝนกะโหลก',dur:2.2,col:'#c08cff',desc:'กะโหลกผีตกจากฟ้าทั่วจอ',ic:'ic_m_skull',hue:60},
 a_snipe:{name:'ศรพิฆาต',dur:1.6,col:'#9fe8ff',desc:'ชาร์จแล้วยิงศรยักษ์ทะลุทุกตัว',ic:'ic_a_pierce',hue:180},
 a_split:{name:'ศรแยกร่าง',dur:1.8,col:'#d0ff8a',desc:'ศรโดนแล้วแตกเป็น 5 ดอกไล่ล่า',ic:'ic_a_fan',hue:120},
 a_storm:{name:'พายุศร',dur:2.0,col:'#bdf',desc:'หมุนตัวยิงรอบทิศ',ic:'ic_a_rain',hue:220},
 a_eagle:{name:'เหยี่ยวเพลิง',dur:2.0,col:'#ffb347',desc:'ปล่อยเหยี่ยวไฟไล่ล่าศัตรู',ic:'ic_a_phoenix',hue:300},
};
const icId=id=>SK[id].ic||('ic_'+id),icCss=id=>SK[id].hue?`filter:hue-rotate(${SK[id].hue}deg) saturate(1.3)`:'';
function drawIcon(id,x,y,w,h,a=1){const im=IMG[icId(id)];if(!ok(im))return;ctx.save();ctx.globalAlpha*=a;if(SK[id].hue)ctx.filter=`hue-rotate(${SK[id].hue}deg) saturate(1.3)`;ctx.drawImage(im,x,y,w,h);ctx.restore();}
const ORDER_SWORD=['slash','upper','dash','slam','spin','wave','naga','rain','chakra','thunder','fire','clone','pillar','thousand','lotus','vortex','xslash','giant','moon','blink','quake','tornado','meteor','garuda'];
const CAP=[6,10,15,22,32,45,60];
const SYN_SWORD=[['slash','upper','ฟันเสยต่อเนื่อง',1.5],['upper','slam','ทุบดาวตก',2.5],['dash','thousand','พันดาบเงา',2],['spin','rain','พายุฝนดาบ',1.8],
 ['thunder','wave','คลื่นสายฟ้า',2],['naga','fire','นาคเพลิง',2],['upper','pillar','เสาส่งฟ้า',2],['clone','xslash','กากบาทพันเงา',2.2],
 ['lotus','thousand','บัวพันกลีบ',2],['vortex','giant','ทัณฑ์สวรรค์',3],['moon','blink','จันทร์เงา',2],['quake','meteor','วันสิ้นโลก',2.5],['tornado','garuda','พายุครุฑ',2.2]];

const ORDERS={sword:ORDER_SWORD,shaman:['m_orb','m_bell','m_tal','m_skull','m_hand','m_summon','m_curse','m_drain','m_ritual','m_chain','m_fire','m_mirror','m_rain'],archer:['a_rapid','a_fan','a_pierce','a_bomb','a_leap','a_rain','a_vine','a_phoenix','a_meteor','a_snipe','a_split','a_storm','a_eagle']};
const SYNS={sword:SYN_SWORD,
 shaman:[['m_orb','m_skull','ไฟผีกะโหลก',1.6],['m_bell','m_summon','ปลุกผีทั้งป่า',2],['m_curse','m_hand','มือมรณะ',2.2],['m_skull','m_drain','กลืนวิญญาณ',2],['m_tal','m_ritual','ยันต์มหาพิธี',2.5],['m_chain','m_rain','พายุวิญญาณ',2],['m_mirror','m_fire','ไฟผีคู่',2]],
 archer:[['a_rapid','a_pierce','ทะลวงต่อเนื่อง',1.6],['a_leap','a_rain','ฝนธนูฟ้าถล่ม',2],['a_vine','a_bomb','กับดักระเบิด',2.2],['a_fan','a_phoenix','หงส์พันศร',2],['a_bomb','a_meteor','ศรเทวะถล่มโลก',3],['a_snipe','a_split','ศรพันทิศ',2.2],['a_storm','a_eagle','พายุเหยี่ยว',2]]};
const CLS={sword:{n:'นักดาบ',kp:'h_',hp:100,col:'#ff6b5b',desc:'ฟันระยะประชิด สกิลเยอะสุด 24 ท่า',def:['slash','upper','dash','slash']},
 shaman:{n:'หมอผี',kp:'m_',hp:85,col:'#b98cff',desc:'ร่ายไฟวิญญาณ เรียกผี สาปศัตรู ระยะกลาง',def:['m_orb','m_bell','m_orb']},
 archer:{n:'นักธนู',kp:'a_',hp:90,col:'#7fdc4a',desc:'ยิงไกล ฝนธนู ศรระเบิด ระยะไกลสุด',def:['a_rapid','a_fan','a_rapid']}};
let cls='sword',ORDER=ORDER_SWORD,SYN=SYN_SWORD;
function readSave(c){let s=null;try{s=JSON.parse(localStorage.getItem('mahacombo-'+c)||'null');if(!s&&c==='sword')s=JSON.parse(localStorage.getItem('combo-proto')||'null');}catch(e){}return s;}
let save=Object.assign({stage:1,chain:['slash','upper','dash','slash'],found:[]},readSave('sword')||{});
function persist(){try{localStorage.setItem('mahacombo-'+cls,JSON.stringify(save));localStorage.setItem('mahacombo-last',cls);}catch(e){}}
let stage=save.stage,chain=save.chain.filter(id=>SK[id]),found=new Set(save.found);
const unlockedN=()=>Math.min(ORDER.length,1+2*stage);
const needStage=i=>Math.floor((i-1)/2);
const capOf=()=>CAP[Math.min(stage-1,CAP.length-1)]+(typeof eq!=='undefined'?tot('ct'):0);
const isUnlocked=id=>ORDER.indexOf(id)<unlockedN();
const chainTime=()=>chain.reduce((a,id)=>a+SK[id].dur,0);

// ================= ภาพ =================
const IMG={};
const ASSETS=['bg',...[0,1,2,3].map(i=>'h_atk'+i),...[0,1,2,3,4,5].map(i=>'h_run'+i),...[0,1,2,3,4,5,6,7].map(i=>'h_sp'+i),
 ...[0,1,2,3].map(i=>'g'+i),...[0,1,2,3].map(i=>'y'+i),...[0,1,2,3].map(i=>'s'+i),...[0,1,2,3].map(i=>'b'+i),...[0,1,2,3].map(i=>'o'+i),...['weapon','armor','charm'].flatMap(k=>[0,1,2].map(r=>'it_'+k+r)),
 'ui_coin','ui_stone','town','bg_forest','bg_ruins','bg_sky','npc_m','npc_s','npc_r','npc_merchant','npc_smith','fx_slashG','fx_slashC','fx_burst','fx_shock','fx_giant','fx_naga','fx_chakra','fx_lotus','fx_fire','fx_pillar',...[...new Set(Object.keys(SK).map(icId))],
 ...['m_','a_'].flatMap(k=>[...[0,1,2,3].map(i=>k+'atk'+i),...[0,1,2,3,4,5].map(i=>k+'run'+i),...[0,1,2,3,4,5,6,7].map(i=>k+'sp'+i)]),
 'fx_m_orb','fx_m_tal','fx_m_hand','fx_m_skull','fx_m_circle','fx_m_sigil','fx_a_arrow','fx_a_green','fx_a_boom','fx_a_phoenix','fx_a_vine','fx_a_giant',...[0,1,2,3,4].flatMap(r=>['it_staff'+r,'it_bow'+r]),'it_boots','it_helm','it_ring','it_bracelet','it_crown',...[0,1,2,3,4].map(r=>'it_ear'+r)];
function loadAssets(cb){let n=ASSETS.length;ASSETS.forEach(k=>{const i=new Image();i.onload=i.onerror=()=>{if(--n===0)cb();};i.src='assets/'+k+'.webp';IMG[k]=i;});}
const ok=im=>im&&im.complete&&im.naturalWidth>0;
const TC={};function tint(im,col){const k=im.src+col;if(TC[k])return TC[k];const c=document.createElement('canvas');c.width=im.naturalWidth||1;c.height=im.naturalHeight||1;const g=c.getContext('2d');g.drawImage(im,0,0);g.globalCompositeOperation='source-atop';g.fillStyle=col;g.fillRect(0,0,c.width,c.height);return TC[k]=c;}
// ขนาดเฟรม (หน่วยพิกเซลในเกม) และจุดเท้า ax
const FM={
 h_atk:[{w:124,h:171,ax:.536},{w:129,h:147,ax:.384},{w:199,h:138,ax:.337},{w:157,h:149,ax:.389}],
 h_run:[{w:135,h:147,ax:.452},{w:137,h:147,ax:.467},{w:125,h:140,ax:.556},{w:137,h:141,ax:.412},{w:127,h:146,ax:.366},{w:125,h:147,ax:.352}],
 h_sp:[{w:109,h:179,ax:.5},{w:112,h:183,ax:.5},{w:168,h:150,ax:.372},{w:187,h:121,ax:.324},{w:122,h:198,ax:.549},{w:145,h:143,ax:.493},{w:144,h:150,ax:.444},{w:150,h:162,ax:.653}],
 m_atk:[{w:132,h:162,ax:.496},{w:160,h:153,ax:.359},{w:183,h:150,ax:.32},{w:126,h:156,ax:.437}],
 m_run:[{w:108,h:158,ax:.486},{w:107,h:159,ax:.547},{w:125,h:154,ax:.392},{w:124,h:150,ax:.565},{w:117,h:153,ax:.466},{w:115,h:151,ax:.409}],
 m_sp:[{w:116,h:190,ax:.509},{w:104,h:150,ax:.452},{w:132,h:147,ax:.451},{w:119,h:149,ax:.584},{w:108,h:136,ax:.444},{w:120,h:164,ax:.504},{w:132,h:138,ax:.58},{w:114,h:154,ax:.588}],
 a_atk:[{w:118,h:153,ax:.47},{w:123,h:153,ax:.472},{w:135,h:153,ax:.437},{w:127,h:153,ax:.476}],
 a_run:[{w:106,h:151,ax:.476},{w:104,h:151,ax:.481},{w:112,h:144,ax:.411},{w:111,h:129,ax:.473},{w:103,h:144,ax:.5},{w:104,h:145,ax:.327}],
 a_sp:[{w:110,h:153,ax:.614},{w:107,h:134,ax:.495},{w:124,h:127,ax:.399},{w:129,h:143,ax:.484},{w:117,h:142,ax:.342},{w:125,h:145,ax:.52},{w:123,h:132,ax:.524},{w:116,h:151,ax:.586}],
 g:[{w:77,h:69,ax:.5},{w:76,h:85,ax:.5},{w:74,h:74,ax:.5},{w:72,h:68,ax:.5}],
 s:[{w:101,h:117,ax:.703},{w:99,h:118,ax:.707},{w:103,h:117,ax:.665},{w:103,h:119,ax:.665}],
 b:[{w:85,h:93,ax:.5},{w:87,h:75,ax:.5},{w:86,h:76,ax:.5},{w:85,h:75,ax:.5}],
 o:[{w:131,h:171,ax:.481},{w:130,h:171,ax:.427},{w:129,h:168,ax:.496},{w:126,h:171,ax:.54}],
 y:[{w:109,h:140,ax:.495},{w:106,h:139,ax:.448},{w:109,h:141,ax:.514},{w:108,h:138,ax:.56}]};
const cyc=(arr,fps)=>arr[Math.floor(t0*fps)%arr.length];
function heroFrame(){const r=heroFrame0();return[CLS[cls].kp+r[0].slice(2),r[1]];}
function heroFrame0(){const p=P;
  if(p.finisher>0)return['h_sp',7];
  if(finale&&finale.phase===2&&!finale.result&&p.blink!==undefined)return[['h_atk',2],['h_sp',2],['h_sp',3],['h_atk',3],['h_sp',0],['h_sp',1]][p.blink%6];
  if(p.hurt>0&&!run)return['h_sp',6];
  if(p.cnt)return[['h_atk',1],['h_sp',2],['h_atk',3],['h_sp',3]][p.cnt.n%4];
  if(p.coreA>0){const el=.55-p.coreA;return cls==='sword'?(el<.16?['h_sp',3]:['h_atk',3]):(el<.15?['h_sp',4]:['h_sp',5]);}
  if(p.dodgeT>0&&p.dodgeAge<.22)return['h_sp',3];
  if(run){const id=chain[run.i],t=run.t,st=run.st;
    switch(id){
      case 'm_orb':case 'm_skull':return cyc([['h_atk',1],['h_atk',2],['h_atk',3],['h_atk',2]],14);
      case 'm_bell':return['h_sp',1];
      case 'm_tal':return cyc([['h_sp',2],['h_atk',2]],6);
      case 'm_hand':return['h_sp',4];
      case 'm_summon':return['h_sp',0];
      case 'm_curse':case 'm_drain':return['h_sp',3];
      case 'm_ritual':return t<1.9?['h_sp',5]:['h_sp',4];
      case 'a_rapid':return cyc([['h_atk',1],['h_atk',2],['h_atk',3]],20);
      case 'a_fan':return['h_sp',5];
      case 'a_pierce':case 'a_phoenix':return['h_sp',3];
      case 'a_bomb':case 'a_vine':return['h_sp',2];
      case 'a_leap':return P.ground?['h_sp',4]:['h_sp',1];
      case 'a_rain':case 'a_meteor':return['h_sp',0];
      case 'slash':return cyc([['h_atk',1],['h_atk',2],['h_atk',3],['h_atk',2]],18);
      case 'upper':return['h_sp',0];
      case 'dash':return t<.33?['h_sp',3]:['h_atk',3];
      case 'slam':return !st.f?['h_sp',0]:(!st.s?['h_sp',1]:['h_atk',2]);
      case 'spin':case 'lotus':return cyc([['h_sp',2],['h_atk',2]],12);
      case 'wave':return['h_atk',Math.min(3,Math.floor(Math.min(.999,Math.max(0,run.acc)/.3)*4))];
      case 'rain':case 'thunder':case 'giant':case 'vortex':return['h_sp',4];
      case 'thousand':return cyc([['h_atk',1],['h_atk',2],['h_sp',2],['h_sp',3],['h_atk',3]],20);
      case 'naga':case 'fire':return['h_sp',3];
      case 'chakra':case 'pillar':return['h_sp',5];
      case 'clone':return cyc([['h_atk',1],['h_atk',2],['h_atk',3]],12);
      case 'xslash':return t<.3?['h_sp',3]:['h_atk',3];
      case 'moon':case 'blink':return cyc([['h_atk',1],['h_atk',2],['h_sp',2],['h_atk',3]],14);
      case 'quake':case 'meteor':case 'garuda':return t<.25?['h_sp',0]:['h_sp',4];
      case 'tornado':return cyc([['h_sp',2],['h_sp',5]],10);
      case 'm_fire':case 'm_rain':return['h_sp',4];
      case 'm_chain':return cyc([['h_sp',3],['h_atk',2]],8);
      case 'm_mirror':return['h_sp',5];
      case 'a_snipe':return t<.7?['h_sp',2]:['h_sp',3];
      case 'a_split':case 'a_eagle':return['h_sp',3];
      case 'a_storm':return cyc([['h_atk',1],['h_atk',2],['h_atk',3]],18);
    }}
  if(p.atkA>0){const k=1-p.atkA/p.atkMax;
    if(cls!=='sword')return['h_atk',Math.min(3,Math.floor(k*4))];
    if(p.airAtk)return k<.4?['h_sp',2]:['h_atk',3];
    if(p.atkStep===0)return['h_atk',Math.min(3,Math.floor(k*4))];
    if(p.atkStep===1)return k<.3?['h_atk',1]:['h_sp',2];
    if(p.atkStep===2)return k<.2?['h_atk',0]:(k<.8?['h_sp',3]:['h_atk',3]);
    return k<.25?['h_atk',0]:(k<.6?['h_sp',0]:['h_atk',2]);}
  if(!p.ground)return['h_run',p.vy<0?4:3];
  if(Math.abs(p.vx)>60)return['h_run',2+Math.floor(t0*12)%4];
  return['h_run',Math.floor(t0*2.5)%2];}

// ================= มอนสเตอร์ =================
const ET={
 ghost:{gold:5,name:'ผีน้อย',fk:'g',hp:30,w:46,h:62,sp:[95,150],dmg:8,kb:1,fps:8,hover:1,drop:.04,gib:['#7fdc4a','#ffcf4a','#3f9a2a'],mm:'#7fdc4a',wind:.5,reach:22,lunge:520,lean:.12},
 skel:{gold:7,name:'ทหารโครงกระดูก',fk:'s',hp:48,w:50,h:105,sp:[120,165],dmg:10,kb:.9,fps:9,drop:.05,gib:['#f1e6c8','#ffcf4a','#8a6a3a'],mm:'#f1e6c8',wind:.55,reach:40,lunge:760,lean:.16},
 bird:{gold:6,name:'ปักษาไฟ',fk:'b',hp:28,w:62,h:52,sp:[150,200],dmg:9,kb:1.1,fps:11,fly:1,drop:.045,gib:['#ff7a3d','#ffcf4a','#ff3d1f'],mm:'#ff9a3d'},
 yak:{gold:18,name:'ยักษ์',fk:'y',hp:130,w:72,h:118,sp:[60,80],dmg:14,kb:.5,fps:7,drop:.12,gib:['#c8202e','#ffcf4a','#7a1018'],mm:'#ff5b6e',wind:.75,reach:55,armor:1,brk:60,lunge:260,lean:.3},
 golem:{gold:60,name:'ยักษ์หินทวารบาล',fk:'o',hp:420,w:100,h:165,sp:[40,55],dmg:22,kb:.22,fps:5,drop:.45,gib:['#9a948a','#ffcf4a','#5a554e'],mm:'#c9c2b8',wind:.95,reach:85,armor:1,brk:150,lunge:0,lean:.08,pound:1},
};
const MODE={
 easy:{n:'ง่าย',col:'#7fdc4a',pw:.3,hp0:.75,grow:1.22,dmg:.6,gold:1.5,stone:1.7,drop:1.4,price:.75,enh:12,breakAt:99,desc:'มอนเลือดน้อย เงินและหินดรอปเยอะ ของถูก ตีบวกไม่มีวันลดขั้น'},
 normal:{n:'ปกติ',col:'#5fb8ff',pw:.22,hp0:1,grow:1.35,dmg:1,gold:1,stone:1,drop:1,price:1,enh:0,breakAt:10,desc:'สมดุล ตีบวกตั้งแต่ +10 ขึ้นไป ถ้าล้มเหลวจะลดลง 1 ขั้น'},
 hard:{n:'ยาก',col:'#ff5b6e',pw:.16,hp0:1.3,grow:1.5,dmg:1.45,gold:.8,stone:.7,drop:.8,price:1.3,enh:-10,breakAt:7,desc:'มอนเลือดหนา ตีแรง ของแพง หินหายาก ตีบวกตั้งแต่ +7 ล้มเหลวลดขั้น'}};
let mode=save.mode||null;const MD=()=>MODE[mode||'normal'];
const hpScale=()=>MD().hp0*Math.pow(MD().grow,stage-1);
function pickType(){const w={ghost:5,skel:stage>=1?3:0,bird:stage>=2?3:1.2,yak:1+stage*.3,golem:stage>=3?.25+.12*stage:(stage===2?.15:0)};
  let t=Math.random()*Object.values(w).reduce((a,b)=>a+b,0);for(const k in w){t-=w[k];if(t<=0)return k;}return 'ghost';}

// ================= อุปกรณ์ =================
const RAR=[{n:'ธรรมดา',c:'#d6dbe4',m:1},{n:'ดี',c:'#7fdc4a',m:1.3},{n:'หายาก',c:'#5fb8ff',m:1.7},{n:'มหากาพย์',c:'#c77dff',m:2.2},{n:'ตำนาน',c:'#ffb02e',m:3}];
const SLOTS=['weapon','armor','helm','boots','charm','ring','ear'];
const SLOTN={weapon:'อาวุธ',armor:'เกราะ',helm:'หมวก',boots:'รองเท้า',charm:'เครื่องราง',ring:'แหวน',ear:'ต่างหูคริ'};
const INAME={armor:['เสื้อเกราะหนัง','เกราะเหล็กลายกนก','เกราะเงินลายไทย','เกราะนิลกาฬ','เกราะทองสุริยะ'],charm:['ตะกรุดทองแดง','ผ้ายันต์แดง','พระเครื่องเงิน','เขี้ยวเสือสมิง','แก้วมณีโชติ'],
 helm:['หมวกหนัง','หมวกเหล็ก','หมวกเงินลายไทย','มงกุฎนิล','ชฎาทองเทวะ'],boots:['รองเท้าหนัง','รองเท้าพรานป่า','รองเท้าเงินลม','รองเท้ามรกต','รองเท้าวายุเทพ'],ring:['แหวนทองเหลือง','แหวนเงิน','แหวนทับทิม','กำไลหยก','แหวนนพเก้า'],ear:['ต่างหูเงิน','ต่างหูกริชทับทิม','ต่างหูดาบไพลิน','ต่างหูเพชรดำ','ต่างหูดาวสังหาร']};
const WNAME={sword:['ดาบเหล็กกล้า','ดาบคมกริบ','ดาบเงินนาคา','ดาบอสูรม่วง','ดาบทองเทวะ'],shaman:['ไม้เท้าไม้ตะเคียน','ไม้เท้าเงินกระดิ่ง','ไม้เท้าทองพราย','ไม้เท้าอเมทิสต์','ไม้เท้าวิญญาณเทวะ'],archer:['ธนูไม้ไผ่','ธนูเงินพราน','ธนูทองนาคา','ธนูหยกมรกต','ธนูหงส์เพลิง']};
const STN={atk:['โจมตี','%'],hp:['HP',''],def:['ลดดาเมจ','%'],crit:['คริ','%'],cdmg:['แรงคริ','%'],en:['เกจ','%'],gold:['เงิน','%'],spd:['ความเร็ว','%'],ls:['ดูดเลือด','%'],ct:['เวลาคอมโบ',' วิ']};
const SUFX={atk:'แห่งพลัง',hp:'แห่งชีวิต',def:'แห่งหินผา',crit:'แห่งคมดาบ',cdmg:'แห่งการสังหาร',en:'แห่งสายลม',gold:'แห่งทรัพย์',spd:'แห่งพายุ',ls:'แห่งโลหิต',ct:'แห่งกาลเวลา'};
const SW={atk:1,hp:.25,def:3,crit:3,cdmg:1,en:1,gold:.5,spd:1.5,ls:6,ct:15};
const MAIN={weapon:lv=>({atk:lv*20}),armor:lv=>({hp:lv*24,def:3+lv*1.6}),helm:lv=>({hp:lv*14,def:1.5+lv*.7}),boots:lv=>({spd:4+lv*.8,def:1+lv*.6}),charm:lv=>({crit:2+lv,en:6+lv*1.5}),ring:lv=>({cdmg:8+lv*3,gold:5+lv*1.5}),ear:lv=>({crit:3+lv*1.2,cdmg:10+lv*3.5})};
const SUBV={atk:lv=>lv*6,hp:lv=>lv*10,def:lv=>1+lv*.6,crit:lv=>1+lv*.5,cdmg:lv=>4+lv*1.5,en:lv=>3+lv,gold:lv=>4+lv,spd:lv=>2+lv*.5,ls:lv=>.5+lv*.25,ct:lv=>.5};
function makeItem(slot,r,lv){const m=RAR[r].m,rnd=(a,b)=>a+Math.random()*(b-a);const it={slot,r,lv,main:{},subs:[]};
  const mb=MAIN[slot](lv);for(const k in mb)it.main[k]=Math.max(1,Math.round(mb[k]*m*rnd(.9,1.1)));
  const pool=Object.keys(SUBV).filter(k=>!(k in it.main)&&(k!=='ct'||r>=3));const n=[0,1,1,2,3][r];
  for(let i=0;i<n&&pool.length;i++){const k=pool.splice(Math.floor(Math.random()*pool.length),1)[0];it.subs.push({k,v:k==='ct'?(r>=4?1:.5):Math.max(1,Math.round(SUBV[k](lv)*rnd(.7,1.2)*(1+r*.15)))});}
  if(it.subs.length)it.suf=SUFX[it.subs[0].k];return it;}
function normItem(it){if(!it||it.main)return it;const r={0:0,1:2,2:4}[it.r]??0;const n={slot:it.slot,r,lv:it.lv,main:{},subs:[],plus:it.plus||0};
  if(it.atk)n.main.atk=it.atk;if(it.hp)n.main.hp=it.hp;if(it.def)n.main.def=it.def;if(it.crit)n.main.crit=it.crit;if(it.en)n.main.en=it.en;return n;}
function rollR(bonus=0){const x=Math.random()*100-stage*.6-bonus;return x<1.2?4:x<5?3:x<15?2:x<40?1:0;}
const pm=it=>1+(it.plus||0)*.12+Math.max(0,(it.plus||0)-9)*.1;
const mainV=(it,k)=>k==='def'?Math.round(it.main[k]*(1+(it.plus||0)*.04)):Math.round(it.main[k]*pm(it));
function itemStats(it){const o={};for(const k in it.main)o[k]=(o[k]||0)+mainV(it,k);for(const s of it.subs)o[s.k]=(o[s.k]||0)+s.v;return o;}
const fmtS=(k,v)=>`${STN[k][0]} +${v}${STN[k][1]}`;
const istat=it=>{const parts=Object.keys(it.main).map(k=>fmtS(k,mainV(it,k)));const subs=it.subs.map(s=>`<i style="color:#9fe8ff;font-style:normal">${fmtS(s.k,s.v)}</i>`);return parts.join(' · ')+(subs.length?'<br>'+subs.join(' · '):'');};
const istatTxt=it=>Object.keys(it.main).map(k=>fmtS(k,mainV(it,k))).concat(it.subs.map(s=>fmtS(s.k,s.v))).join(' · ');
const iname=it=>(it.slot==='weapon'?WNAME[cls][it.r]:INAME[it.slot][it.r])+(it.suf?' '+it.suf:'')+(it.plus?' +'+it.plus:'');
const iicon=it=>{const r=it.r;switch(it.slot){case 'weapon':return cls==='shaman'?'it_staff'+r:cls==='archer'?'it_bow'+r:'it_weapon'+[0,0,1,1,2][r];
  case 'armor':return 'it_armor'+[0,0,1,1,2][r];case 'charm':return 'it_charm'+[0,0,1,1,2][r];case 'helm':return r>=3?'it_crown':'it_helm';case 'boots':return 'it_boots';case 'ring':return r===3?'it_bracelet':'it_ring';case 'ear':return 'it_ear'+r;}};
const iscore=it=>{if(!it)return 0;const st=itemStats(it);let s=0;for(const k in st)s+=st[k]*(SW[k]||1);return Math.round(s);};
let eq=save.eq||{weapon:makeItem('weapon',0,1)},bag=save.bag||[];
function normAll(){for(const k of SLOTS)eq[k]=normItem(eq[k])||null;bag=bag.map(normItem);}
normAll();
function restoreCombo(){
  chain=chain.filter(id=>ORDER.includes(id)&&isUnlocked(id));
  if(!chain.length)chain=CLS[cls].def.slice();
  while(chainTime()>capOf()+1e-6)chain.pop();
}
function tot(k){let s=0;for(const sl of SLOTS){const it=eq[sl];if(!it)continue;if(k in it.main)s+=mainV(it,k);for(const x of it.subs)if(x.k===k)s+=x.v;}return s;}
const atkMul=()=>1+tot('atk')/100;
const maxHpOf=()=>CLS[cls].hp+tot('hp');
const defOf=()=>Math.min(.75,tot('def')/100);
const critOf=()=>Math.min(.8,.12+tot('crit')/100);
const cdmgOf=()=>2+tot('cdmg')/100;
const enMul=()=>1+tot('en')/100;
const goldMul=()=>1+tot('gold')/100;
const spdMul=()=>Math.min(1.6,1+tot('spd')/100);
const lsOf=()=>Math.min(.3,tot('ls')/100);
restoreCombo();
let gold=save.gold||0,stones=save.stones||0;
function saveEq(){delete save.test;save.eq=eq;save.bag=bag;save.gold=gold;save.stones=stones;save.mode=mode;persist();}
function gainItem(it){const cur=eq[it.slot];let msg;
  if(iscore(it)>iscore(cur)){eq[it.slot]=it;if(cur)bag.unshift(cur);msg='สวมใส่แล้ว!';const old=P.maxHp;P.maxHp=maxHpOf();P.hp=Math.min(P.maxHp,P.hp+Math.max(0,P.maxHp-old));}
  else{bag.unshift(it);msg='เก็บเข้ากระเป๋า';}
  if(bag.length>24){bag.sort((a,b)=>iscore(b)-iscore(a));bag.length=24;}
  saveEq();pickups.push({it,msg,life:2.8,max:2.8});if(pickups.length>4)pickups.shift();}
function equipFromBag(i){const it=bag[i];if(!it)return;const cur=eq[it.slot];eq[it.slot]=it;bag.splice(i,1);if(cur)bag.unshift(cur);P.maxHp=maxHpOf();P.hp=Math.min(P.hp,P.maxHp);saveEq();}

// ================= เสียง (สังเคราะห์สด: มีห้องก้อง + คอมเพรสเซอร์ + เพลงประกอบ) =================
let AC=null,muted=false,noise=null,lastSnd=0,MB=null,RV=null,DRY=null,musicOn=true;
function ac(){if(!AC){try{AC=new (window.AudioContext||window.webkitAudioContext)();const sr=AC.sampleRate,n=sr*.6;noise=AC.createBuffer(1,n,sr);const d=noise.getChannelData(0);for(let i=0;i<n;i++)d[i]=Math.random()*2-1;
    const comp=AC.createDynamicsCompressor();comp.threshold.value=-14;comp.knee.value=10;comp.ratio.value=5;comp.attack.value=.003;comp.release.value=.2;
    MB=AC.createGain();MB.gain.value=.9;MB.connect(comp).connect(AC.destination);
    const ir=AC.createBuffer(2,sr*1.8,sr);for(let c=0;c<2;c++){const x=ir.getChannelData(c);for(let i=0;i<x.length;i++)x[i]=(Math.random()*2-1)*Math.pow(1-i/x.length,2.6);}
    RV=AC.createConvolver();RV.buffer=ir;const rg=AC.createGain();rg.gain.value=.35;RV.connect(rg).connect(MB);DRY=MB;}catch(e){AC=null}}
  if(AC&&AC.state==='suspended')AC.resume();return AC;}
const T=()=>AC.currentTime;
function out(node,rev=0){node.connect(MB);if(rev>0){const g=AC.createGain();g.gain.value=rev;node.connect(g).connect(RV);}}
function env(g,t,v,a,d){g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(Math.max(.0002,v),t+a);g.gain.exponentialRampToValueAtTime(.0001,t+a+d);}
function nz(freq,q,v,dur,type='bandpass',rev=.1,f1){if(!AC||muted)return;const t=T();const s=AC.createBufferSource();s.buffer=noise;s.playbackRate.value=.8+Math.random()*.4;const f=AC.createBiquadFilter();f.type=type;f.frequency.setValueAtTime(freq,t);if(f1)f.frequency.exponentialRampToValueAtTime(f1,t+dur);f.Q.value=q;
  const g=AC.createGain();env(g,t,v,.004,dur);s.connect(f).connect(g);out(g,rev);s.start(t,Math.random()*.3);s.stop(t+dur+.05);}
function osc(type,f0,f1,dur,v,rev=.15,a=.004,det=0){if(!AC||muted)return;const t=T();const o=AC.createOscillator();o.type=type;o.frequency.setValueAtTime(f0,t);o.frequency.exponentialRampToValueAtTime(Math.max(1,f1),t+dur);o.detune.value=det;
  const g=AC.createGain();env(g,t,v,a,dur);o.connect(g);out(g,rev);o.start(t);o.stop(t+a+dur+.05);}
function sTone(f0,f1,dur,v=.3,type='sine'){osc(type,f0,f1,dur,v*.8,.2);}
// เสียงปะทะ: น้ำหนักและย่านเสียงต่างกันตามวัสดุของศัตรู
function sHit(p=1,v=.14,material='body'){
  if(!AC||muted||T()-lastSnd<.045)return;
  lastSnd=T();
  const strength=Math.min(1.4,v*7);
  osc('sine',135*p,45,.11,.34*strength,0);
  nz(720*p,.9,.32*strength,.08,'lowpass',.08,210);
  if(material==='bone'){
    nz(2700*p,2.2,.26*strength,.065,'bandpass',.14);
    osc('triangle',1150*p,740*p,.10,.06*strength,.12);
  }else if(material==='stone'){
    nz(1650*p,1.2,.30*strength,.16,'bandpass',.20,490);
    nz(4200,1.5,.11*strength,.04,'highpass',.10);
  }else{
    nz(3600*p,.8,.19*strength,.055,'bandpass',.10,1200);
  }
}
// ดาบแหวกอากาศ: เสียงกวาดขึ้นและตกตามจังหวะฟัน
function sSwish(){
  if(!AC||muted)return;
  const f=rand(780,1120);
  nz(f,1.1,.19,.15,'bandpass',.12,f*2.6);
  nz(f*3,1.4,.09,.065,'bandpass',.06,f*.85);
}
// แรงระเบิด: แรงอัดช่วงต้น ตามด้วยเสียงก้องและเศษกระจาย
function sBoom(v=.7){
  if(!AC||muted)return;
  osc('sine',104,28,.72,v*.68,.2);
  nz(2400,.65,v*.62,.08,'bandpass',.15,700);
  nz(650,.7,v*.7,.55,'lowpass',.46,85);
  nz(3600,1.2,v*.21,.24,'bandpass',.32,680);
}
// สายธนูดีดและเสียงลูกศรแหวกอากาศ
function sTwang(){
  if(!AC||muted)return;
  const f=rand(255,290);
  osc('triangle',f,f*.87,.13,.17,.09,.002);
  osc('sine',f*2.9,f*2.65,.062,.09,.10,.002);
  nz(1800,2.1,.15,.028,'bandpass',.05);
  nz(5800,1.1,.09,.1,'bandpass',.12,2100);
}
function sMagic(base=600){
  if(!AC||muted)return;
  osc('sine',base*.54,base,.22,.12,.48,.018);
  osc('triangle',base*1.48,base*1.6,.25,.05,.4,.03);
  nz(2300,1.7,.13,.19,'bandpass',.45,5200);
}
function sCrit(){
  if(!AC||muted)return;
  osc('sine',158,42,.21,.37,0);
  nz(4400,1.7,.33,.07,'bandpass',.18,1800);
  osc('triangle',1700,1440,.24,.08,.35,.002);
  osc('sine',2520,2250,.31,.04,.42,.003);
}
function sCoin(){if(!AC||muted)return;osc('square',1900,1900,.05,.03,.2,.002);setTimeout(()=>osc('square',2540,2540,.09,.03,.3,.002),55);}
function sUI(){osc('triangle',880,1320,.06,.05,.1,.002);}
// ===== เพลงประกอบ: สเกลเพนทาโทนิกแบบไทย (ระนาด + กลองทน + ฉิ่ง) =====
const PENTA=[0,2,4,7,9];let mus=null;
function noteF(i,base=262){const o=Math.floor(i/5),d=((i%5)+5)%5;return base*Math.pow(2,o+(PENTA[d]/12));}
function pluck(f,t,v,dur=.35){const o=AC.createOscillator(),o2=AC.createOscillator(),g=AC.createGain(),f2=AC.createBiquadFilter();o.type='triangle';o2.type='square';o.frequency.value=f;o2.frequency.value=f*2.01;
  f2.type='lowpass';f2.frequency.setValueAtTime(f*6,t);f2.frequency.exponentialRampToValueAtTime(f*1.5,t+dur);const g2=AC.createGain();g2.gain.value=.12;
  o.connect(f2);o2.connect(g2).connect(f2);f2.connect(g);g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(v,t+.004);g.gain.exponentialRampToValueAtTime(.0001,t+dur);
  g.connect(mus.bus);o.start(t);o2.start(t);o.stop(t+dur+.05);o2.stop(t+dur+.05);}
function drum(t,low,v){const o=AC.createOscillator(),g=AC.createGain();o.type='sine';o.frequency.setValueAtTime(low?120:220,t);o.frequency.exponentialRampToValueAtTime(low?50:140,t+.18);g.gain.setValueAtTime(v,t);g.gain.exponentialRampToValueAtTime(.0001,t+.25);o.connect(g).connect(mus.bus);o.start(t);o.stop(t+.3);}
function ching(t,v,open){const s=AC.createBufferSource();s.buffer=noise;const f=AC.createBiquadFilter();f.type='highpass';f.frequency.value=6500;const g=AC.createGain();g.gain.setValueAtTime(v,t);g.gain.exponentialRampToValueAtTime(.0001,t+(open?.5:.08));s.connect(f).connect(g).connect(mus.bus);s.start(t,Math.random()*.3);s.stop(t+.6);}
const MEL=[[7,9,10,9,7,5,7,-1, 5,7,9,7,5,4,2,-1],[10,9,7,9,10,12,10,9, 7,5,4,5,7,-1,7,-1],[2,4,5,7,5,4,2,0, 2,4,5,4,2,-1,0,-1]];
function musicStart(){if(!AC||mus)return;mus={bus:AC.createGain(),step:0,next:T()+.1,bar:0,tm:null,calm:false};mus.bus.gain.value=muted||!musicOn?0:.16;mus.bus.connect(MB);const rg=AC.createGain();rg.gain.value=.4;mus.bus.connect(rg).connect(RV);
  mus.tm=setInterval(()=>{if(!AC)return;const bpm=mus.calm?92:132,sp=60/bpm/2;while(mus.next<T()+.25){const t=mus.next,st=mus.step%16,bar=Math.floor(mus.step/16);const mel=MEL[bar%MEL.length][st];
      if(mel>=0&&(!mus.calm||st%2===0))pluck(noteF(mel,mus.calm?196:262),t,mus.calm?.16:.2,mus.calm?.6:.32);
      if(!mus.calm&&st%4===2)pluck(noteF(mel>=0?mel-5:0,131),t,.08,.25);
      if(st%8===0)drum(t,true,mus.calm?.25:.5);if(!mus.calm&&(st%8===3||st%8===6))drum(t,false,.28);if(!mus.calm&&st%4===2)drum(t,true,.18);
      ching(t,st%4===0?.09:.035,st%4===0);
      mus.step++;mus.next+=sp;}},60);}
function musicVol(){if(mus)mus.bus.gain.setTargetAtTime(muted||!musicOn?0:(finale&&finale.phase<2?.04:.16),T(),.2);}

// ================= สถานะ =================
const P={x:200,y:GY,vx:0,vy:0,face:1,hp:100,maxHp:100,inv:0,ihit:0,core:0,coreA:0,dodgeT:0,dodgeAge:9,dodgeCD:0,dodgeX:0,cnt:null,hc:0,hcT:0,atkCD:0,atkStep:0,swing:0,ground:true,atkA:0,atkMax:1,hurt:0,land:0,finisher:0,curKey:'',prevKey:'',swT:0};
let enemies=[],parts=[],fxs=[],projs=[],texts=[],trail=[],drops=[],pickups=[];
let energy=0,kills=0,quota=30,spawnT=0,state='edit',afterEdit='start',doomedN=0;
let timeScale=1,hitstop=0,shake=0,zoom=1,zoomT=1,desat=0,desatT=0,flash=0,dark=0,darkT=0,chroma=0,blackT=0;
let tut=null;const TS={ee:0,cnt:0,core:0,brk:0,dodge:0,jump:0,fin:0};
let eeT=0,eeMax=2.4,eeSrc=null,lights=[],motes=[],punch=0;
let run=null,finale=null,bigTotal=null,banner=null,toast=null,t0=0,cracks=null;
let scene='stage',goldT=0,camLead=0,WORLD_W=4200,camX=0,portalX=4000;
const keys={};
const rand=(a,b)=>a+Math.random()*(b-a);
const dmgScale=()=>1+.22*(stage-1);

// ================= ปุ่ม =================
// ใช้ e.code = ปุ่มจริงบนคีย์บอร์ด กดได้แม้เปิดภาษาไทยอยู่
const KM={ArrowLeft:'left',KeyA:'left',ArrowRight:'right',KeyD:'right',KeyS:'jump',ArrowUp:'jump',KeyW:'jump',Space:'jump',KeyZ:'atk',KeyX:'skill',ShiftLeft:'dodge',ShiftRight:'dodge',KeyF:'core'};
addEventListener('keydown',e=>{ac();const c=e.code;const k=KM[c];
  if(state==='title'){if(c==='Enter'||c==='Space'){e.preventDefault();startFromTitle();}return;}
  if(state==='edit'||state==='msg'){if(document.getElementById('modeSel').classList.contains('show')||document.getElementById('classSel').classList.contains('show'))return;if(c==='Enter'||c==='KeyC'||c==='Space'){e.preventDefault();if(state==='edit')closeEditor();else document.getElementById('mGo').click();}return;}
  if(scene==='town'&&state==='play'&&(c==='KeyW'||c==='ArrowUp'||c==='Enter'||c==='KeyE')){e.preventDefault();if(!e.repeat)talk();return;}
  if(k){keys[k]=true;e.preventDefault();if(e.repeat)return;press(k);}
  if(c==='KeyC'||c==='Tab'){e.preventDefault();if(state==='play'&&!run&&!finale){openEditor(scene==='town'?'town':'resume');}}
  if(c==='Escape'&&tut&&state==='play'){e.preventDefault();finishTutorial(true);return;}
  if(c==='KeyM'){muted=!muted;musicVol();}if(c==='KeyN'){musicOn=!musicOn;musicVol();}});
addEventListener('keyup',e=>{const k=KM[e.code];if(k)keys[k]=false;});
addEventListener('blur',()=>{for(const k in keys)keys[k]=false;});
addEventListener('pointerdown',()=>{ac();try{window.focus();}catch(e){}});
document.querySelectorAll('#touch .b').forEach(b=>{const k=b.dataset.k;
  b.addEventListener('pointerdown',e=>{e.preventDefault();ac();b.classList.add('on');if(k==='edit'){if(state==='play'&&!run&&!finale){if(scene==='town'&&nearNpc)talk();else openEditor(scene==='town'?'town':'resume');}return;}keys[k]=true;press(k);});
  const up=()=>{keys[k]=false;b.classList.remove('on');};b.addEventListener('pointerup',up);b.addEventListener('pointerleave',up);b.addEventListener('pointercancel',up);});
function press(k){if(k==='skill')tryRelease();else if(k==='jump')jump();else if(k==='dodge')dodge();else if(k==='core')startCore();else if(k==='atk'&&eeT>0&&!P.cnt&&state==='play')startCounter();}
function jump(){if(state==='play'&&P.ground&&!finale&&!(run&&['slam','dash','xslash'].includes(chain[run.i]))){TS.jump++;P.vy=-780;P.ground=false;P.jt=.14;for(let i=0;i<8;i++)parts.push({x:P.x+rand(-20,20),y:GY,vx:rand(-120,120),vy:rand(-120,-30),life:.35,max:.35,col:'#b8a088',sz:rand(3,6),g:300,solid:1});}}

// ================= เอฟเฟกต์ =================
function arc(x,y,r,a0,a1,col,w=10,life=.18,face=1){fxs.push({t:'arc',x,y,r,a0,a1,col,w,life,max:life,face});}
function ring(x,y,r0,r1,col,life=.35,w=8){fxs.push({t:'ring',x,y,r0,r1,col,life,max:life,w});}
function line(x1,y1,x2,y2,col,w,life){fxs.push({t:'line',x1,y1,x2,y2,col,w,life,max:life});}
function bolt(x,y2,col){const pts=[];let y=-20,cx=x+rand(-40,40);while(y<y2){pts.push([cx,y]);y+=rand(30,60);cx=x+rand(-28,28);}pts.push([x,y2]);fxs.push({t:'bolt',pts,col,life:.22,max:.22});}
function spr(name,x,y,size,rot=0,flip=1,life=.2,grow=1.25,alpha=1){fxs.push({t:'spr',name,x,y,size,rot,flip,life,max:life,grow,alpha});}
function sparks(x,y,col,n=6,sp=420){for(let i=0;i<n;i++){const a=rand(0,Math.PI*2),s=rand(.3,1)*sp;parts.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-120,life:rand(.25,.5),max:.5,col,sz:rand(2,4),g:900});}}
function gibs(x,y,e){const cols=ET[e.type].gib;
  for(let i=0;i<(e.heavy?18:11);i++){const a=rand(-Math.PI,0),s=rand(250,900);parts.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s,life:rand(.6,1.1),max:1.1,col:cols[i%3],sz:rand(5,11),g:1800,rot:rand(0,6),vr:rand(-20,20),solid:1});}}
function addText(x,y,v,crit,big){texts.push({x,y,vy:-170,txt:v.toLocaleString(),col:big?'#ff4d5e':crit?'#ffd76a':'#fff',sz:big?40:crit?28:18,life:big?1.1:.8,max:big?1.1:.8});}
function say(t,col='#fff',dur=1.4){toast={t,col,life:dur,max:dur};}

// ================= ต่อสู้ =================
function damage(e,base,kx,ky,opt){
  if(e.dead)return;const air=e.y<GY-8;const crit=Math.random()<critOf();
  let v=Math.round(base*(run?run.mult:1)*(.85+Math.random()*.3)*((opt&&opt.air&&air)?2:1)*atkMul()*(crit?cdmgOf():1)*(e.broken>0?1.5:1));
  const T=ET[e.type],armored=T.armor&&e.wind>0&&!(e.broken>0);
  e.hp-=v;e.hitT=.1;if(!armored)e.stun=Math.max(e.stun,.45);e.aggro=true;if(!armored){e.vx=kx*e.kb;if(ky){e.vy=ky*Math.min(1,e.kb+.15);e.ground=false;}}
  e.tilt=Math.max(-.4,Math.min(.4,(e.tilt||0)+Math.sign(kx||0)*(armored?.06:.22)));
  if(T.brk&&!(e.broken>0)){e.brkV=(e.brkV||0)+(opt&&opt.brk!==undefined?opt.brk:base*(run?.12:.55));if(e.brkV>=e.brkMax)breakEnemy(e);}
  if(!run&&!finale){if(!(opt&&opt.noCore))P.core=Math.min(100,P.core+(cls==='sword'?3:5));P.hc=(P.hcT>0?P.hc:0)+1;P.hcT=2.2;}
  if(!run||Math.random()<.2)light(e.x,e.y-e.h/2,crit?220:130,crit?'255,210,90':'190,220,255',crit?.55:.3);
  sparks(e.x,e.y-e.h/2,run?SK[chain[run.i]].col:'#fff',crit?10:5);if(crit)critFx(e,v);
  if(!run||crit||Math.random()<.25)spr('fx_burst',e.x+rand(-8,8),e.y-e.h/2,crit?150:95,rand(0,6),1,.13,1.3);
  if(!crit&&(!run||Math.random()<.25))addText(e.x+rand(-14,14),e.y-e.h-8,v,false);
  if(lsOf()>0&&!finale)P.hp=Math.min(P.maxHp,P.hp+Math.min(3,v*lsOf()*.02));
  if(run){run.hits++;run.dmg+=v;e.marked=true;}else if(!finale){energy=Math.min(100,energy+7*enMul());}
  sHit(e.heavy?.6:1,.14,e.type==='golem'?'stone':e.type==='skel'?'bone':'body');
  if(e.hp<=0&&!e.doomed){if((run||finale)&&doomedN<50){e.doomed=true;doomedN++;}else kill(e);}
}
function hitRect(x,y,w,h,d,kx,ky,opt){let n=0;for(const e of enemies){if(e.dead)continue;if(e.x+e.w/2>x&&e.x-e.w/2<x+w&&e.y>y&&e.y-e.h<y+h){damage(e,d,typeof kx==='function'?kx(e):kx,ky,opt);n++;}}return n;}
function hitCircle(cx,cy,r,d,kxF,ky,opt){let n=0;for(const e of enemies){if(e.dead)continue;const dx=e.x-cx,dy=(e.y-e.h/2)-cy;if(dx*dx+dy*dy<(r+e.w/2)**2){damage(e,d,kxF(e),ky,opt);n++;}}return n;}
const front=(w,h,d,kx,ky,opt)=>hitRect(P.face>0?P.x-10:P.x-w+10,P.y-h,w,h,d,kx,ky,opt);
const outward=(s,cx)=>e=>Math.sign(e.x-(cx===undefined?P.x:cx)||1)*s;
const near=(r,x=P.x)=>enemies.filter(e=>!e.dead&&Math.abs(e.x-x)<r);
let critCD=0,critFl=0;
function critFx(e,v){const x=e.x,y=e.y-e.h/2,heavy=critCD<=0;
  texts.push({x:x+rand(-10,10),y:e.y-e.h-14,vy:-200,txt:v.toLocaleString(),col:'#ffe14a',sz:heavy?38:30,life:1,max:1,crit:1,pop:.18});
  if(!heavy){if(Math.random()<.35)spr('fx_slashC',x,y,150,rand(0,6),1,.15,1.3);return;}
  critCD=run?.14:.05;critFl=Math.min(.6,critFl+.35);
  const a=rand(-.6,.6);spr('fx_slashG',x,y,300,a+.75,1,.22,1.25);spr('fx_slashC',x,y,300,a-.75,-1,.22,1.25);spr('fx_burst',x,y,230,rand(0,6),1,.25,1.6);
  ring(x,y,10,130,'#ff3040',.3,8);ring(x,y,6,90,'#fff',.22,4);
  for(let i=0;i<14;i++){const an=rand(0,6.3),sp=rand(500,1100);parts.push({x,y,vx:Math.cos(an)*sp,vy:Math.sin(an)*sp,life:.3,max:.3,col:i%2?'#ffe14a':'#ff3040',sz:rand(3,6),g:0});}
  fxs.push({t:'rays',x,y,life:.18,max:.18,a:rand(0,6)});
  texts.push({x,y:e.y-e.h-52,vy:-60,txt:'CRITICAL!',col:'#ff3040',sz:20,life:.7,max:.7,lab:1,pop:.12});
  shake=Math.max(shake,run?5:9);if(!run)hitstop=Math.max(hitstop,.06);sCrit();}
function kill(e,big){if(e.dead)return;e.dead=true;{const T0=ET[e.type],fi=e.cfi||0,dir=Math.sign(e.x-P.x)||1;fxs.push({t:'corpse',k:T0.fk+fi,m:FM[T0.fk][fi],x:e.x,y:e.y,fx:e.fx||1,vx:dir*rand(260,520)*(e.heavy?.5:1),vy:-rand(380,640)*(e.heavy?.6:1),rot:0,vr:dir*rand(5,11),life:.6,max:.6,fly:!T0.fly||1});}(window.__kt=window.__kt||{})[e.type]=(window.__kt[e.type]||0)+1;if(e.doomed)doomedN--;kills++;
  sparks(e.x,e.y-e.h/2,ET[e.type].gib[0],big?26:12,big?700:450);
  if(big){ring(e.x,e.y-e.h/2,10,110,'#fff',.35,6);gibs(e.x,e.y-e.h/2,e);}
  if(!run&&!finale)energy=Math.min(100,energy+4*enMul());
  const T=ET[e.type];const g=Math.max(1,Math.round(T.gold*(1+.3*(stage-1))*MD().gold*goldMul()*rand(.8,1.2)));gold+=g;goldT=.6;if(!run||Math.random()<.15)sCoin();
  if(!run||Math.random()<.3)texts.push({x:e.x+rand(-10,10),y:e.y-e.h-30,vy:-120,txt:'+'+g+' G',col:'#ffd76a',sz:15,life:.7,max:.7});
  const sc={ghost:.012,skel:.018,bird:.016,yak:.06,golem:.3}[e.type]*MD().stone;if(Math.random()<sc)drops.push({x:e.x,y:e.y-e.h/2,vx:rand(-100,100),vy:-560,stone:1,t:0});
  if(Math.random()<T.drop*MD().drop*(run||finale?.6:1)&&drops.length<25){const rr=rollR(e.type==='golem'?8:e.type==='yak'?3:0);
    drops.push({x:e.x,y:e.y-e.h/2,vx:rand(-120,120),vy:-520,it:makeItem(SLOTS[Math.floor(Math.random()*SLOTS.length)],rr,stage),t:0});}}

// ================= ระบบแบบ Solo Leveling: หลบเฉียดฉิว / สวนกลับ / Core / Break =================
// แสงสว่างชั่วครู่ตรงจุดปะทะ (วาดแบบ additive ทำให้ฉากดูมีแสงจริง)
function light(x,y,r,rgb,a,life=.16){if(lights.length<40)lights.push({x,y,r,rgb,a,life,max:life});}
const perfWin=()=>MD().pw||.22;
function inStrikeRange(e,px){const T=ET[e.type];return Math.abs(e.x-px)<e.w/2+(T.reach||30)+14&&Math.abs((e.y-e.h/2)-(P.y-70))<Math.max(80,e.h/2+30);}
function dodge(){if(state!=='play'||run||finale||P.cnt||P.coreA>0||P.dodgeCD>0||P.finisher>0)return;
  const mv=(keys.right?1:0)-(keys.left?1:0),dir=mv||P.face;P.face=dir;
  TS.dodge++;P.dodgeT=.32;P.dodgeAge=0;P.dodgeCD=.5;P.dodgeX=P.x;P.inv=Math.max(P.inv,.32);P.vx=dir*980;if(!P.ground)P.vy=Math.min(P.vy,0);
  nz(1300,.9,.14,.16,'bandpass',.12,500);for(let i=0;i<10;i++)parts.push({x:P.x+rand(-14,14),y:GY-rand(0,10),vx:-dir*rand(120,360),vy:rand(-120,-20),life:.4,max:.4,col:'rgba(200,215,255,.8)',sz:rand(3,6),g:200,solid:1});}
function extremeEvade(e){TS.ee++;eeT=eeMax;eeSrc=e;P.inv=Math.max(P.inv,.6);window.__ee=(window.__ee||0)+1;
  energy=Math.min(100,energy+10*enMul());P.core=Math.min(100,P.core+35);
  ring(P.x,P.y-80,10,240,'#9fd8ff',.45,10);ring(P.x,P.y-80,6,150,'#fff',.3,4);light(P.x,P.y-80,320,'140,200,255',.7,.4);
  hitstop=Math.max(hitstop,.06);punch=Math.max(punch,.06);osc('sine',1800,600,.5,.12,.6);osc('triangle',2700,2600,.6,.05,.7);nz(6000,.8,.12,.3,'highpass',.5);}
function enemyStrike(e){const T=ET[e.type],dir=Math.sign(P.x-e.x)||1;e.lunge=.22;e.ldir=dir;
  arc(e.x+dir*(e.w*.3),e.y-e.h*.55,e.w*.55+(T.reach||30),dir>0?-1.3:1.3,dir>0?1.1:-1.1,'#ff3040',e.heavy?16:10,.18,1);
  if(e.type==='golem'){ring(e.x+dir*60,GY-6,10,200,'#ffb347',.35,10);shake=Math.max(shake,6);}
  const inR=inStrikeRange(e,P.x)||(P.dodgeT>0&&inStrikeRange(e,P.dodgeX));
  if(!inR)return;
  if(P.dodgeT>0&&P.dodgeAge<=perfWin()){extremeEvade(e);return;}
  if(P.inv>0||P.cnt||P.coreA>0||run||finale)return;
  const dm=Math.max(1,Math.round(T.dmg*MD().dmg*(1+.18*(stage-1))*(1-defOf())*(tut?.4:1)));P.hp-=dm;addText(P.x,P.y-170,dm,false,true);
  P.inv=.9;P.ihit=.9;P.hurt=.35;P.hc=0;P.vx=dir*420;P.vy=-320;P.ground=false;shake=10;flash=Math.max(flash,.15);light(P.x,P.y-80,200,'255,60,70',.5);sTone(200,80,.2,.2,'square');}
function breakEnemy(e){TS.brk++;e.broken=3.5;e.brkV=e.brkMax;e.wind=0;e.stun=3.5;e.vy=-320;e.ground=false;window.__brk=(window.__brk||0)+1;
  energy=Math.min(100,energy+25*enMul());
  texts.push({x:e.x,y:e.y-e.h-30,vy:-50,txt:'BREAK!',col:'#7ff3ff',sz:40,life:1.3,max:1.3,crit:1,pop:.2});
  ring(e.x,e.y-e.h/2,10,260,'#7ff3ff',.45,14);ring(e.x,e.y-e.h/2,6,170,'#fff',.3,6);spr('fx_burst',e.x,e.y-e.h/2,360,0,1,.35,1.5);
  for(let i=0;i<24;i++){const a=rand(0,6.3),sp=rand(400,900);parts.push({x:e.x,y:e.y-e.h/2,vx:Math.cos(a)*sp,vy:Math.sin(a)*sp,life:.45,max:.45,col:i%2?'#7ff3ff':'#fff',sz:rand(3,6),g:600});}
  light(e.x,e.y-e.h/2,380,'120,240,255',.8,.35);flash=Math.max(flash,.35);shake=Math.max(shake,18);hitstop=Math.max(hitstop,.14);punch=Math.max(punch,.1);sBoom(.6);sCrit();}
function startCounter(){if(run||finale||P.cnt||scene!=='stage')return;let tg=eeSrc&&!eeSrc.dead?eeSrc:nearestEnemy(P.x,P.y-70,520);if(!tg)return;
  TS.cnt++;P.cnt={t:0,n:0,tg,acc:0};P.inv=Math.max(P.inv,1.2);P.vx=0;window.__cnt=(window.__cnt||0)+1;
  texts.push({x:P.x,y:P.y-200,vy:-60,txt:'เงาวาร์ป!',col:'#c9a8ff',sz:26,life:.8,max:.8,lab:1,pop:.12});osc('sawtooth',140,900,.25,.12,.4);}
function updateCounter(dt){const C=P.cnt;C.t+=dt;C.acc+=dt;
  while(C.acc>=.085&&C.n<7){C.acc-=.085;let e=C.tg;if(!e||e.dead)e=C.tg=nearestEnemy(P.x,P.y-70,600);if(!e){C.n=7;break;}
    const side=C.n%2?1:-1,last=C.n===6;trail.push(ghostOf());P.x=Math.max(24,Math.min(WORLD_W-24,e.x+side*62));P.y=Math.min(GY,e.y);P.face=-side;P.vy=-40;
    const a=rand(-.9,.9);spr(C.n%2?'fx_slashC':'fx_slashG',e.x,e.y-e.h/2,last?420:240,a,P.face,.2,1.25);line(e.x-Math.cos(a)*160,e.y-e.h/2-Math.sin(a)*160,e.x+Math.cos(a)*160,e.y-e.h/2+Math.sin(a)*160,'#e6d8ff',last?16:7,.18);
    damage(e,last?90:28,last?-side*520:-side*30,last?-620:-60,{brk:last?30:9});sSwish();
    if(last){flash=Math.max(flash,.3);shake=Math.max(shake,20);hitstop=Math.max(hitstop,.1);punch=Math.max(punch,.08);sBoom(.5);ring(e.x,e.y-e.h/2,10,200,'#c9a8ff',.35,10);}
    C.n++;}
  if(C.n>=7&&C.t>.7){P.cnt=null;eeT=Math.min(eeT,.25);}}
const CORE_N={sword:'ฟันแยกฟ้า',shaman:'ระเบิดวิญญาณ',archer:'ศรทะลวงฟ้า'};
function startCore(){if(state!=='play'||scene!=='stage'||run||finale||P.cnt||P.coreA>0||P.finisher>0)return;
  if(P.core<100){say('Core ยังไม่เต็ม — ฟันธรรมดาเพื่อเติม','#ff8a8a');return;}
  TS.core++;P.core=0;P.coreA=.55;P.coreS={};P.inv=Math.max(P.inv,.65);window.__core=(window.__core||0)+1;
  texts.push({x:P.x,y:P.y-200,vy:-60,txt:CORE_N[cls],col:'#ffe066',sz:26,life:.9,max:.9,lab:1,pop:.12});osc('sawtooth',220,1200,.3,.14,.4);}
function updateCore(dt){const el=.55-P.coreA,st=P.coreS;
  if(cls==='sword'){if(el<.16){P.vx=P.face*1350;trail.push(ghostOf());}
    else if(!st.b){st.b=1;P.vx=0;const x=P.x+P.face*120,y=P.y-90;
      front(360,220,70,P.face*520,-540,{brk:45,noCore:1});spr('fx_slashG',x,y,600,-.35,P.face,.35,1.2);spr('fx_slashC',x,y,520,.45,P.face,.35,1.2);
      line(x-P.face*260,y+70,x+P.face*260,y-80,'#fff',22,.3);light(x,y,420,'255,230,150',.8,.3);
      flash=Math.max(flash,.4);shake=Math.max(shake,24);hitstop=Math.max(hitstop,.12);punch=Math.max(punch,.1);sBoom(.7);sCrit();}}
  else if(cls==='shaman'){if(el>=.18&&!st.b){st.b=1;hitCircle(P.x,P.y-80,310,58,outward(440),-620,{brk:40,noCore:1});
      spr('fx_m_circle',P.x,GY-8,700,0,1,.5,1.15);spr('fx_burst',P.x,P.y-90,600,0,1,.4,1.5);ring(P.x,P.y-80,20,330,'#7ad7ff',.45,14);light(P.x,P.y-90,460,'120,210,255',.8,.35);
      flash=Math.max(flash,.35);shake=Math.max(shake,22);hitstop=Math.max(hitstop,.1);punch=Math.max(punch,.08);sBoom(.7);}}
  else if(el>=.15&&!st.b){st.b=1;bullet({img:'fx_a_green',x:P.x+P.face*60,y:P.y-70,vx:P.face*1900,vy:0,sz:460,r:70,dmg:60,pierce:true,hitIv:9,life:.9,kx:P.face*520,ky:-420,trail:'#7dff9a',opt:{brk:40,noCore:1}});
    light(P.x+P.face*80,P.y-70,360,'130,255,160',.7,.3);flash=Math.max(flash,.25);shake=Math.max(shake,16);hitstop=Math.max(hitstop,.08);punch=Math.max(punch,.06);sBoom(.5);}}

// ================= สกิลแต่ละตัว =================
function pulses(iv,dt){if(run.acc<0)run.acc=iv;run.acc+=dt;let n=0;while(run.acc>=iv){run.acc-=iv;n++;}return n;}
function faceEdge(){if((P.face>0&&P.x>WORLD_W-300)||(P.face<0&&P.x<300))P.face*=-1;}
const TICK={
 slash(dt){let n=pulses(.11,dt);while(n--){const k=run.st.k=(run.st.k||0)+1;const up=k%2;
   spr('fx_slashG',P.x+P.face*62,P.y-82,200,up?0:2.8,P.face,.16,1.15);front(160,130,9,P.face*70,-150);sSwish();}},
 upper(dt){if(!run.st.h){run.st.h=1;P.vy=-520;P.ground=false;}
   let n=pulses(.25,dt);while(n--){spr('fx_slashG',P.x+P.face*50,P.y-100,250,-1.1,P.face,.22,1.2);front(150,160,14,P.face*40,-880);shake=Math.max(shake,5);sSwish();}},
 dash(dt){if(!run.st.d){run.st.d=1;faceEdge();}if(run.t<.33){P.vx=P.face*1200;trail.push(ghostOf());
     let n=pulses(.05,dt);while(n--){hitRect(P.x-80,P.y-120,160,120,10,P.face*260,-320);}
     line(P.x-P.face*110,P.y-75+rand(-25,25),P.x+P.face*30,P.y-75,SK.dash.col,4,.18);}
   else if(!run.st.s){run.st.s=1;P.vx=0;spr('fx_slashC',P.x-P.face*40,P.y-80,330,.3,P.face,.3,1.3);sSwish();}},
 slam(dt){if(!run.st.j){run.st.j=1;P.vy=-980;P.ground=false;}
   if(run.t>.45&&!run.st.f){run.st.f=1;P.vy=2800;}
   if(run.st.f&&P.ground&&!run.st.s){run.st.s=1;spr('fx_shock',P.x,GY-70,560,0,1,.55,1.25);ring(P.x,GY-10,20,340,SK.slam.col,.45,14);ring(P.x,GY-10,10,220,'#fff',.3,6);
     hitCircle(P.x,GY-30,340,30,outward(320),-680,{air:true});shake=22;hitstop=.09;sBoom();groundCrack(P.x);
     for(let i=0;i<30;i++)parts.push({x:P.x+rand(-60,60),y:GY,vx:rand(-600,600),vy:rand(-500,-100),life:.6,max:.6,col:'#a98b6a',sz:rand(3,6),g:1400,solid:1});}},
 spin(dt){P.face=Math.floor(run.t*14)%2?1:-1;let n=pulses(.09,dt);while(n--){const a=run.t*16;spr('fx_slashG',P.x,P.y-75,280,a,1,.14,1.05,.8);arc(P.x,P.y-75,120,a,a+1.6,SK.spin.col,10,.14);arc(P.x,P.y-75,120,a+Math.PI,a+Math.PI+1.6,SK.spin.col,10,.14);
   hitCircle(P.x,P.y-75,175,7,outward(140),-210);sSwish();} if(!P.ground)P.vy=Math.min(P.vy,120);},
 wave(dt){let n=pulses(.3,dt);while(n--){projs.push({k:'wave',x:P.x+P.face*40,y:P.y-80,vx:P.face*980,life:1.2,hit:new Set(),col:SK.wave.col});sTone(900,300,.2,.08,'triangle');}},
 naga(dt){let n=pulses(1.0,dt);while(n--){projs.push({k:'naga',x:P.x+P.face*60,by:P.y-95,y:P.y-95,vx:P.face*820,life:1.6,t:0,last:new Map()});sTone(180,600,.5,.18,'sawtooth');shake=Math.max(shake,6);}},
 rain(dt){let n=pulses(.06,dt);const al=near(560);while(n--)projs.push({k:'sword',x:(al.length&&Math.random()<.5)?al[Math.floor(Math.random()*al.length)].x+rand(-20,20):P.x+rand(-470,470),y:-40,vy:1800,col:SK.rain.col});},
 chakra(dt){let n=pulses(1.1,dt);while(n--){projs.push({k:'chakra',x0:P.x,x:P.x,y:P.y-85,dir:P.face,t:0,life:2.2,last:new Map()});sTone(500,900,.3,.1,'triangle');}},
 thunder(dt){let n=pulses(.28,dt);while(n--){const al=near(650).sort((a,b)=>Math.abs(a.x-P.x)-Math.abs(b.x-P.x)).slice(0,6);
   const pick=[];for(let i=0;i<3&&al.length;i++)pick.push(al.splice(Math.floor(Math.random()*al.length),1)[0]);
   if(!pick.length)pick.push({x:P.x+rand(-300,300),y:GY,h:0,fake:1});
   for(const e of pick){spr('fx_burst',e.x,e.y-e.h/2,150,rand(0,6),1,.25,1.4);bolt(e.x,e.y-e.h/2,SK.thunder.col);ring(e.x,e.y-e.h/2,5,80,SK.thunder.col,.25,5);hitCircle(e.x,e.y-30,85,24,()=>rand(-60,60),-440);}
   flash=Math.max(flash,.22);shake=Math.max(shake,8);sTone(1800,80,.25,.12,'sawtooth');}},
 fire(dt){let n=pulses(.07,dt);while(n--){spr('fx_fire',P.x+P.face*200,P.y-80,400,rand(-.06,.06),P.face,.13,1.08,.95);
   front(400,160,7,P.face*90,-90);for(let i=0;i<3;i++)parts.push({x:P.x+P.face*rand(60,380),y:P.y-rand(40,130),vx:P.face*rand(100,300),vy:rand(-260,-60),life:.5,max:.5,col:['#ff7a3d','#ffcf4a','#ff3d1f'][i],sz:rand(3,7),g:-200});}
   if(Math.random()<.3)nz(400,.5,.08,.2,'lowpass');},
 clone(dt){if(!run.st.c){run.st.c=1;for(let i=0;i<4;i++)projs.push({k:'clone',x:P.x+rand(-60,60),y:GY,face:P.face,cd:rand(0,.2),life:SK.clone.dur,f:0});}},
 pillar(dt){let n=pulses(.2,dt);while(n--){const k=run.st.k=(run.st.k||0)+1;const x=P.x+P.face*(70+k*115);
   spr('fx_pillar',x,GY-190,400,0,1,.45,1.02,.75);ring(x,GY-6,10,90,'#fffbe0',.3,6);hitRect(x-55,GY-420,110,420,22,0,-720);shake=Math.max(shake,6);sTone(1200,400,.25,.08,'triangle');}},
 thousand(dt){let n=pulses(.045,dt);while(n--){const c=near(480);
   if(c.length){const e=c[Math.floor(Math.random()*c.length)];const a=rand(0,Math.PI*2);if(Math.random()<.5)spr(Math.random()<.5?'fx_slashG':'fx_slashC',e.x,e.y-e.h/2,rand(100,150),a,1,.14,1.1,.9);else arc(e.x,e.y-e.h/2,rand(40,70),a,a+2.2,SK.thousand.col,7,.14);damage(e,6,rand(-90,90),-170);}
   else{const a=rand(0,6.3);arc(P.x+rand(-200,200),P.y-rand(40,200),50,a,a+2,SK.thousand.col,6,.14);}if(Math.random()<.4)sSwish();}},
 lotus(dt){P.face=Math.floor(run.t*6)%2?1:-1;let n=pulses(.05,dt);while(n--){spr('fx_lotus',P.x,P.y-90,300+run.t*90,run.t*3,1,.12,1.04,.75);
   const c=near(520);if(c.length){const e=c[Math.floor(Math.random()*c.length)];damage(e,5,rand(-60,60),-200);}
   for(let i=0;i<2;i++){const a=rand(0,6.3),r=rand(60,320);parts.push({x:P.x+Math.cos(a)*r,y:P.y-90+Math.sin(a)*r*.6,vx:-Math.sin(a)*400,vy:Math.cos(a)*240,life:.5,max:.5,col:'#ffb3d9',sz:rand(4,7),g:0,rot:a,vr:8,solid:1});}}},
 vortex(dt){const st=run.st;if(!st.v){st.v=1;st.cx=Math.max(80,Math.min(WORLD_W-80,P.x+P.face*260));st.cy=P.y-120;sTone(90,40,2.2,.3,'sawtooth');}
   if(run.t<1.8){let n=pulses(.1,dt);for(const e of near(520,st.cx)){e.vx=(st.cx-e.x)*3.2;e.vy=((st.cy+e.h/2)-e.y)*4;e.ground=false;e.stun=.3;e.aggro=true;}
     while(n--){for(const e of near(160,st.cx))damage(e,3,0,0);
       for(let i=0;i<6;i++){const a=rand(0,6.3),r=rand(150,330);parts.push({x:st.cx+Math.cos(a)*r,y:st.cy+Math.sin(a)*r*.7,vx:-Math.cos(a)*r*2.6,vy:-Math.sin(a)*r*1.8,life:.38,max:.38,col:i%2?'#9a6bff':'#e2d0ff',sz:3,g:0});}}}
   else if(!st.b){st.b=1;hitCircle(st.cx,st.cy,300,60,outward(600,st.cx),-760);spr('fx_burst',st.cx,st.cy,620,0,1,.5,1.5);spr('fx_shock',st.cx,GY-90,700,0,1,.55,1.2);
     ring(st.cx,st.cy,20,420,'#9a6bff',.5,16);flash=.55;shake=26;hitstop=.1;sBoom();}},
 xslash(dt){const st=run.st;if(!st.s){st.s=1;faceEdge();st.x0=P.x;}
   if(run.t<.3){P.vx=P.face*1300;trail.push(ghostOf());let n=pulses(.05,dt);while(n--)hitRect(P.x-80,P.y-130,160,130,10,P.face*120,-200);}
   else if(!st.e){st.e=1;P.vx=0;st.x1=P.x;sSwish();}
   if(run.t>=.6&&!st.b){st.b=1;const mx=(st.x0+st.x1)/2,my=P.y-110;
     spr('fx_slashG',mx,my,520,.8,1,.5,1.15);spr('fx_slashG',mx,my,520,.8,-1,.5,1.15);
     line(mx-260,my-200,mx+260,my+150,'#fff',26,.45);line(mx+260,my-200,mx-260,my+150,'#fff',26,.45);
     hitRect(mx-280,P.y-320,560,320,70,outward(400,mx),-650);flash=.5;shake=24;hitstop=.11;sBoom(.6);}},
 giant(dt){const st=run.st;if(!st.g&&run.t>=.25){st.g=1;projs.push({k:'giant',x:Math.max(100,Math.min(WORLD_W-100,P.x+P.face*240)),y:-260,vy:2400,landed:false,life:SK.giant.dur-.25});sTone(1500,200,.5,.15,'triangle');}},
};
function bullet(o){projs.push(Object.assign({k:'b',t:0,hit:new Map(),pierce:false,hitIv:9,g:0,life:1,sz:80,r:22,alpha:1},o));}
function aimAt(x,y,sp,face,maxA=.5){let best=null,bd=1e9;for(const e of enemies){if(e.dead)continue;const dx=e.x-x;if(Math.sign(dx)!==face||Math.abs(dx)>720)continue;const ey=e.y-e.h/2+(ET[e.type].hover?-10:0),dy=ey-y;if(Math.abs(dy)>Math.abs(dx)*1.2+60)continue;const d=Math.abs(dx)+Math.abs(dy)*.5;if(d<bd){bd=d;best=[dx,dy];}}
  if(!best)return[face*sp,0];let a=Math.atan2(best[1],Math.abs(best[0]));a=Math.max(-maxA,Math.min(maxA,a));return[face*Math.cos(a)*sp,Math.sin(a)*sp];}
function nearestEnemy(x,y,r){let b=null,bd=r*r;for(const e of enemies){if(e.dead)continue;const dx=e.x-x,dy=(e.y-e.h/2)-y,d=dx*dx+dy*dy;if(d<bd){bd=d;b=e;}}return b;}
function boomAt(p){if(p.split&&!p.didSplit){p.didSplit=1;for(let i=0;i<p.split;i++){const a=-Math.PI/2+(i-(p.split-1)/2)*.55;bullet({img:'fx_a_arrow',x:p.x,y:p.y-10,vx:Math.cos(a)*700*(Math.random()<.5?1:-1),vy:Math.sin(a)*700,sz:90,r:24,dmg:9,life:.9,home:7,homeR:520,spd:900,trail:'#d0ff8a'});}sTwang();}
  if(!p.boom)return;hitCircle(p.x,p.y,p.boom.r,p.boom.d,outward(260,p.x),-420);spr(p.boom.img||'fx_burst',p.x,p.y,p.boom.r*2.6,rand(0,6),1,.3,1.3);if(p.boom.r>90){shake=Math.max(shake,8);sBoom(.3);}else sHit(.7,.1);}
function updateBullet(p,dt){p.t+=dt;p.life-=dt;
  if(p.stuck){p.fuse-=dt;if(p.stuck!=='g'){if(p.stuck.dead)p.stuck='g';else{p.x=p.stuck.x+p.ox;p.y=p.stuck.y-p.stuck.h/2;}}if(p.fuse<=0){boomAt(p);p.life=0;}return;}
  if(p.home){const tg=nearestEnemy(p.x,p.y,p.homeR||500);const sp=p.spd||Math.hypot(p.vx,p.vy)||600;
    if(tg){const a=Math.atan2((tg.y-tg.h/2)-p.y,tg.x-p.x),cur=Math.atan2(p.vy,p.vx);let d=a-cur;while(d>Math.PI)d-=2*Math.PI;while(d<-Math.PI)d+=2*Math.PI;const na=cur+Math.max(-p.home*dt,Math.min(p.home*dt,d));p.vx=Math.cos(na)*sp;p.vy=Math.sin(na)*sp;}
    else if(p.ghost){p.vx+=(P.x-p.x)*dt*2;p.vy+=((P.y-150)-p.y)*dt*2;}}
  if(p.pull)for(const e of enemies){if(e.dead||e.doomed)continue;const dx=p.x-e.x;if(Math.abs(dx)<p.pull&&Math.abs((e.y-e.h/2)-p.y)<200){e.vx=dx*4/(e.heavy?3:1);e.stun=Math.max(e.stun,.15);}}
  p.vy+=p.g*dt;p.x+=p.vx*dt;p.y+=p.vy*dt;
  if(p.trail&&Math.random()<.7)parts.push({x:p.x,y:p.y,vx:-p.vx*.05+rand(-30,30),vy:-p.vy*.05+rand(-30,30),life:.35,max:.35,col:p.trail,sz:rand(3,6),g:0});
  for(const e of enemies){if(e.dead)continue;const ecy=e.y-e.h/2+(ET[e.type].hover?-10:0);if(Math.abs(e.x-p.x)<e.w/2+p.r&&Math.abs(ecy-p.y)<e.h/2+p.r+8){const l=p.hit.get(e);
      if(l===undefined||(p.pierce&&p.t-l>=p.hitIv)){p.hit.set(e,p.t);
        if(p.stickT){p.stuck=e;p.ox=p.x-e.x;p.fuse=p.stickT;damage(e,p.dmg,0,0);return;}
        damage(e,p.dmg,typeof p.kx==='function'?p.kx():(p.kx!==undefined?p.kx:Math.sign(p.vx)*100),p.ky!==undefined?p.ky:-100,p.opt);if(p.hs&&!run)hitstop=Math.max(hitstop,.03);
        if(!p.pierce){boomAt(p);p.life=0;return;}}}}
  if(p.y>=GY-4&&(p.vy>0||p.g>0)){if(p.stickT){p.stuck='g';p.y=GY-6;p.fuse=p.stickT;return;}if(!p.ghost){boomAt(p);p.life=0;}else p.vy=-Math.abs(p.vy);}
  if(p.x<camX-300||p.x>camX+W+300||p.y<-400)p.life=0;}
function drawBullet(p){ctx.save();ctx.translate(p.x,p.y);ctx.globalAlpha=Math.min(1,p.life*4)*p.alpha;
  if(p.ghost){const fi=Math.floor(t0*8+p.sz)%4,m=FM.g[fi],im=IMG['g'+fi];if(p.vx>0)ctx.scale(-1,1);ctx.globalAlpha*=.8;ctx.drawImage(im,-m.w/2,-m.h/2,m.w,m.h);ctx.globalCompositeOperation='lighter';ctx.globalAlpha*=.5;ctx.drawImage(tint(im,'#7affd9'),-m.w/2,-m.h/2,m.w,m.h);ctx.restore();return;}
  const im=IMG[p.img];if(!ok(im)){ctx.restore();return;}ctx.globalCompositeOperation='lighter';
  if(p.spin)ctx.rotate(p.t*p.spin);else if(p.face){if(p.vx<0)ctx.scale(-1,1);}else ctx.rotate(Math.atan2(p.vy,p.vx));
  const w=p.sz,h=p.sz*(im.naturalHeight/im.naturalWidth);ctx.drawImage(im,-w/2,-h/2,w,h);ctx.restore();}
Object.assign(TICK,{
 m_orb(dt){let n=pulses(.16,dt);while(n--){bullet({img:'fx_m_orb',x:P.x+P.face*60,y:P.y-75+rand(-15,15),r:30,vx:P.face*760,vy:rand(-60,60),sz:100,dmg:13,life:1.1,home:3,boom:{r:70,d:6},trail:'#7ad7ff',kx:P.face*150,ky:-160});sMagic(rand(500,700));}},
 m_bell(dt){let n=pulses(.3,dt);while(n--){ring(P.x,P.y-80,20,330,'#9fe8ff',.45,10);ring(P.x,P.y-80,10,230,'#fff',.3,5);hitCircle(P.x,P.y-80,330,10,outward(260),-260);for(const e of near(330))e.stun=Math.max(e.stun,.7);sTone(1760,1700,.6,.12,'sine');sTone(2640,2600,.5,.06,'sine');}},
 m_tal(dt){let n=pulses(.2,dt);while(n--){bullet({img:'fx_m_tal',x:P.x+P.face*40,y:P.y-110,vx:P.face*rand(420,720),vy:rand(-520,-300),g:1300,sz:70,dmg:6,life:2.2,stickT:.5,boom:{r:120,d:26},spin:12,trail:'#ffd76a'});sSwish();}},
 m_skull(dt){let n=pulses(.14,dt);while(n--){bullet({img:'fx_m_skull',x:P.x,y:P.y-140,vx:P.face*rand(300,500),vy:rand(-300,-100),sz:80,dmg:11,life:1.8,home:5,homeR:700,trail:'#c08cff',kx:P.face*120,ky:-200,face:1});nz(900,1,.06,.1);}},
 m_hand(dt){let n=pulses(.22,dt);while(n--){const c=near(520);const x=c.length?c[Math.floor(Math.random()*c.length)].x:P.x+P.face*rand(100,400);spr('fx_m_hand',x,GY-90,210,0,Math.random()<.5?1:-1,.45,1.05);hitRect(x-60,GY-210,120,210,20,0,-820);shake=Math.max(shake,5);
   for(let i=0;i<10;i++)parts.push({x:x+rand(-40,40),y:GY,vx:rand(-200,200),vy:rand(-400,-100),life:.5,max:.5,col:'#6a4a8a',sz:rand(3,6),g:1400,solid:1});nz(300,.6,.12,.2,'lowpass');}},
 m_summon(dt){if(!run.st.s){run.st.s=1;for(let i=0;i<3;i++)bullet({ghost:1,x:P.x-P.face*40+i*30,y:P.y-120-i*20,vx:rand(-100,100),vy:-200,sz:i*7,dmg:12,life:SK.m_summon.dur,home:6,homeR:900,spd:520,pierce:true,hitIv:.25,r:40,kx:()=>rand(-100,100),ky:-260});sTone(200,600,.6,.15,'sine');}},
 m_curse(dt){const st=run.st;if(!st.c){st.c=1;st.list=near(480);for(const e of st.list)e.curse=1;sTone(120,60,1.2,.3,'sawtooth');}
   let n=pulses(.2,dt);while(n--){for(const e of st.list){if(e.dead)continue;e.vx*=.2;e.stun=Math.max(e.stun,.25);damage(e,5,0,0);if(Math.random()<.3)sparks(e.x,e.y-e.h/2,'#b98cff',3,150);}}
   if(run.t>SK.m_curse.dur-.25&&!st.b){st.b=1;for(const e of st.list){if(e.dead)continue;damage(e,30,0,-500);spr('fx_burst',e.x,e.y-e.h/2,180,rand(0,6),1,.3,1.4);}flash=.25;shake=12;sBoom(.4);}},
 m_drain(dt){let n=pulses(.1,dt);while(n--){const c=near(420).slice(0,4);run.st.tg=c;for(const e of c){damage(e,6,Math.sign(P.x-e.x)*40,0);P.hp=Math.min(P.maxHp,P.hp+.6);}if(Math.random()<.3)nz(200,.4,.06,.15,'lowpass');}},
 m_ritual(dt){const st=run.st;if(!st.r){st.r=1;st.x=P.x;sTone(80,160,1.8,.3,'sawtooth');}
   if(run.t<1.9){let n=pulses(.15,dt);while(n--){for(const e of near(380,st.x))damage(e,3,(st.x-e.x)*.5,0);}}
   else if(!st.b){st.b=1;hitCircle(st.x,GY-60,400,70,outward(500,st.x),-900,{air:true});spr('fx_m_circle',st.x,GY-10,820,0,1,.5,1.2);spr('fx_burst',st.x,GY-120,700,0,1,.5,1.5);
     for(let i=-3;i<=3;i++)spr('fx_m_orb',st.x+i*110,GY-170,280,0,1,.55,1.6);flash=.6;shake=28;hitstop=.12;sBoom(.9);}},
 a_rapid(dt){let n=pulses(.08,dt);while(n--){const v=aimAt(P.x+P.face*50,P.y-78,1400,P.face);bullet({img:'fx_a_arrow',x:P.x+P.face*50,y:P.y-78+rand(-10,10),vx:v[0],vy:v[1]+rand(-30,30),sz:110,r:26,dmg:8,life:.7,kx:P.face*80,ky:-60});sTwang();}},
 a_fan(dt){let n=pulses(.35,dt);while(n--){for(let i=0;i<7;i++){const a=-.4+i*.12;bullet({img:'fx_a_arrow',x:P.x+P.face*50,y:P.y-75,r:26,vx:P.face*Math.cos(a)*1200,vy:Math.sin(a)*1200,sz:110,dmg:10,life:.8,kx:P.face*120,ky:-120});}sSwish();}},
 a_pierce(dt){let n=pulses(.45,dt);while(n--){bullet({img:'fx_a_green',x:P.x+P.face*60,y:P.y-62,vx:P.face*1500,vy:0,sz:260,r:52,dmg:24,pierce:true,life:1,kx:P.face*380,ky:-300,trail:'#7dff9a'});shake=Math.max(shake,6);sTone(800,200,.2,.12,'sawtooth');}},
 a_bomb(dt){let n=pulses(.3,dt);while(n--){bullet({img:'fx_a_arrow',x:P.x+P.face*50,y:P.y-95,vx:P.face*900,vy:-280,g:700,sz:120,dmg:10,life:1.6,boom:{r:130,d:25,img:'fx_a_boom'},trail:'#ffb347'});sTone(900,500,.1,.06,'triangle');}},
 a_leap(dt){if(!run.st.j){run.st.j=1;P.vy=-950;P.ground=false;}if(!P.ground&&run.t>.2){P.vy=Math.min(P.vy,60);let n=pulses(.07,dt);while(n--){const a=.5+rand(0,.5);bullet({img:'fx_a_arrow',x:P.x+P.face*20,y:P.y-80,vx:P.face*Math.cos(a)*1300,vy:Math.sin(a)*1300,sz:110,dmg:10,life:.6,boom:{r:50,d:5},kx:P.face*60,ky:-200});}}},
 a_rain(dt){let n=pulses(.05,dt);const al=near(560);while(n--){const x=(al.length&&Math.random()<.6)?al[Math.floor(Math.random()*al.length)].x+rand(-30,30):P.x+rand(-460,460);bullet({img:'fx_a_arrow',x:x-120,y:-40,vx:300,vy:1500,sz:110,dmg:11,life:1.2,boom:{r:40,d:4}});}},
 a_vine(dt){let n=pulses(.2,dt);while(n--){const k=run.st.k=(run.st.k||0)+1;if(k<=6){const x=P.x+P.face*(80+k*90);spr('fx_a_vine',x,GY-70,220,0,Math.random()<.5?1:-1,1.6-k*.15,1.0,.95);nz(250,.5,.08,.2,'lowpass');}
   const x0=P.x+P.face*80,x1=P.x+P.face*640;for(const e of enemies){if(e.dead)continue;if((e.x-x0)*(e.x-x1)<=0&&e.y>GY-200){e.stun=Math.max(e.stun,.4);e.vx*=.1;damage(e,6,0,0);}}}},
 a_phoenix(dt){if(!run.st.p&&run.t>.3){run.st.p=1;bullet({img:'fx_a_phoenix',x:P.x+P.face*80,y:P.y-75,vx:P.face*700,vy:0,sz:340,r:80,dmg:18,pierce:true,hitIv:.12,life:1.7,kx:P.face*300,ky:-320,trail:'#ffb347'});sTone(300,1200,.6,.2,'sawtooth');shake=10;}},
 moon(dt){let n=pulses(.42,dt);while(n--){bullet({img:'fx_slashC',x:P.x+P.face*50,y:P.y-90,vx:P.face*950,vy:0,sz:320,r:75,dmg:20,pierce:true,hitIv:.2,life:1,kx:P.face*260,ky:-260,face:1,trail:'#cfe6ff'});spr('fx_slashG',P.x+P.face*60,P.y-90,300,-.3,P.face,.2,1.2);sSwish();sTone(700,240,.25,.08,'triangle');}},
 blink(dt){let n=pulses(.13,dt);while(n--){const st=run.st;st.hit=st.hit||new Set();let c=near(620).filter(e=>!st.hit.has(e));if(!c.length){st.hit.clear();c=near(620);}
   if(!c.length){const a=rand(0,6.3);arc(P.x+rand(-150,150),P.y-rand(60,180),60,a,a+2,SK.blink.col,7,.15);continue;}
   const e=c[Math.floor(Math.random()*c.length)];st.hit.add(e);const side=Math.random()<.5?1:-1;trail.push(ghostOf());P.x=Math.max(24,Math.min(WORLD_W-24,e.x+side*60));P.face=-side;
   const a=rand(-.8,.8);spr(Math.random()<.5?'fx_slashG':'fx_slashC',e.x,e.y-e.h/2,230,a,P.face,.18,1.2);line(e.x-Math.cos(a)*140,e.y-e.h/2-Math.sin(a)*140,e.x+Math.cos(a)*140,e.y-e.h/2+Math.sin(a)*140,'#fff',6,.15);
   damage(e,26,-side*120,-240);sSwish();}},
 quake(dt){let n=pulses(.16,dt);while(n--){const k=run.st.k=(run.st.k||0)+1;if(k>9)continue;const x=P.x+P.face*(60+k*95);
   spr('fx_shock',x,GY-50,260,0,1,.4,1.15);groundCrack(x);hitRect(x-55,GY-210,110,210,20,0,-780,{air:true});shake=Math.max(shake,7);if(k%2)sBoom(.25);
   for(let i=0;i<12;i++)parts.push({x:x+rand(-40,40),y:GY,vx:rand(-220,220),vy:rand(-750,-250),life:.7,max:.7,col:i%2?'#a98b6a':'#ffb37a',sz:rand(4,9),g:1700,rot:rand(0,6),vr:rand(-15,15),solid:1});}},
 tornado(dt){if(!run.st.t){run.st.t=1;bullet({img:'fx_slashG',x:P.x+P.face*80,y:P.y-95,vx:P.face*380,vy:0,sz:300,r:95,dmg:7,pierce:true,hitIv:.12,life:2.1,spin:16,pull:230,kx:()=>rand(-80,80),ky:-160,trail:'#b8f5c8'});sTone(120,60,2,.2,'sawtooth');}
   if(Math.random()<.5)sSwish();},
 meteor(dt){let n=pulses(.11,dt);const al=near(620);while(n--){const x=(al.length&&Math.random()<.65)?al[Math.floor(Math.random()*al.length)].x+rand(-30,30):P.x+rand(-480,480);
   bullet({img:'fx_fire',x:x-330,y:-60,vx:650,vy:1350,sz:130,r:30,dmg:12,life:1.4,boom:{r:85,d:14},trail:'#ff9a3d'});}},
 garuda(dt){const st=run.st;if(!st.g&&run.t>.25){st.g=1;bullet({img:'fx_a_phoenix',x:P.x-P.face*380,y:P.y-170,vx:P.face*950,vy:40,sz:560,r:140,dmg:24,pierce:true,hitIv:.15,life:1.6,kx:P.face*300,ky:-520,trail:'#ffd76a'});flash=Math.max(flash,.3);shake=Math.max(shake,12);sTone(300,1400,.6,.2,'sawtooth');}
   if(st.g&&!st.b&&run.t>1.2){st.b=1;hitCircle(P.x+P.face*200,P.y-90,320,40,outward(500,P.x),-600,{air:true});spr('fx_burst',P.x+P.face*200,P.y-90,560,0,1,.45,1.4);ring(P.x+P.face*200,P.y-90,20,360,'#ffd76a',.45,14);flash=.4;shake=22;hitstop=.1;sBoom(.7);}},
 m_fire(dt){let n=pulses(.22,dt);while(n--){const k=run.st.k=(run.st.k||0)+1;for(let i=0;i<3;i++){const a=k*.9+i*2.09,x=P.x+Math.cos(a)*230;
   bullet({img:'fx_m_orb',x,y:GY-10,vx:0,vy:-620,sz:150,r:46,dmg:12,pierce:true,hitIv:.3,life:.65,trail:'#7ad7ff',kx:()=>rand(-60,60),ky:-420});}ring(P.x,GY-6,30,240,'#7ad7ff',.3,6);sMagic(rand(300,450));}},
 m_chain(dt){let n=pulses(.3,dt);while(n--){let fx=P.x+P.face*40,fy=P.y-90;const used=new Set();for(let j=0;j<6;j++){let b=null,bd=330*330;for(const e of enemies){if(e.dead||used.has(e))continue;const dx=e.x-fx,dy=(e.y-e.h/2)-fy,d=dx*dx+dy*dy;if(d<bd){bd=d;b=e;}}
     if(!b)break;used.add(b);const tx=b.x,ty=b.y-b.h/2;const pts=[];for(let i=0;i<=6;i++){const k=i/6;pts.push([fx+(tx-fx)*k+(i&&i<6?rand(-18,18):0),fy+(ty-fy)*k+(i&&i<6?rand(-18,18):0)]);}
     fxs.push({t:'bolt',pts,col:'#9fe8ff',life:.2,max:.2});damage(b,14,Math.sign(tx-fx)*80,-150);spr('fx_burst',tx,ty,120,rand(0,6),1,.15,1.3);fx=tx;fy=ty;}
   flash=Math.max(flash,.12);sTone(1600,120,.2,.1,'sawtooth');}},
 m_mirror(dt){let n=pulses(.2,dt);while(n--){for(const o of [-1,1]){const cx=P.x+o*95;const hf=heroFrame();trail.push({x:cx,y:P.y,f:P.face,k:hf[0]+hf[1],m:FM[hf[0]][hf[1]],life:.25});
     bullet({img:'fx_m_orb',x:cx+P.face*50,y:P.y-90,vx:P.face*700,vy:rand(-80,80),sz:95,r:28,dmg:10,life:1,home:3.5,boom:{r:55,d:5},trail:'#b98cff',kx:P.face*120,ky:-140});}sMagic(rand(520,720));}},
 m_rain(dt){let n=pulses(.07,dt);const al=near(560);while(n--){const x=(al.length&&Math.random()<.6)?al[Math.floor(Math.random()*al.length)].x+rand(-30,30):P.x+rand(-460,460);
   bullet({img:'fx_m_skull',x,y:-40,vx:rand(-60,60),vy:1150,sz:80,r:26,dmg:9,life:1.2,boom:{r:52,d:5},trail:'#c08cff',face:1});}},
 a_snipe(dt){const st=run.st;if(run.t<.7){if(Math.random()<.8){const a=rand(0,6.3),r=rand(80,160);parts.push({x:P.x+P.face*50+Math.cos(a)*r,y:P.y-78+Math.sin(a)*r,vx:-Math.cos(a)*r*3,vy:-Math.sin(a)*r*3,life:.3,max:.3,col:'#9fe8ff',sz:3,g:0});}
     if(!st.c){st.c=1;sTone(200,1200,.7,.12,'sine');}light(P.x+P.face*50,P.y-78,90+run.t*200,'150,230,255',.3,.05);}
   else if(!st.f){st.f=1;bullet({img:'fx_a_green',x:P.x+P.face*60,y:P.y-75,vx:P.face*2600,vy:0,sz:560,r:60,dmg:90,pierce:true,hitIv:9,life:.8,kx:P.face*600,ky:-420,trail:'#9fe8ff',opt:{brk:30}});
     line(P.x,P.y-75,P.x+P.face*1200,P.y-75,'#fff',14,.25);flash=.4;shake=20;hitstop=.1;sBoom(.6);}},
 a_split(dt){let n=pulses(.45,dt);while(n--){const v=aimAt(P.x+P.face*50,P.y-80,1200,P.face);bullet({img:'fx_a_arrow',x:P.x+P.face*50,y:P.y-80,vx:v[0],vy:v[1],sz:140,r:30,dmg:18,life:1,split:5,trail:'#d0ff8a',kx:P.face*150,ky:-160});sTwang();}},
 a_storm(dt){P.face=Math.floor(run.t*10)%2?1:-1;let n=pulses(.045,dt);while(n--){const a=run.t*13;for(const o of [0,Math.PI]){const an=a+o;bullet({img:'fx_a_arrow',x:P.x,y:P.y-85,vx:Math.cos(an)*1150,vy:Math.sin(an)*700,sz:100,r:24,dmg:7,life:.6});}if(Math.random()<.4)sTwang();}},
 a_eagle(dt){let n=pulses(.4,dt);while(n--){bullet({img:'fx_a_phoenix',x:P.x,y:P.y-130,vx:P.face*520,vy:-220,sz:190,r:50,dmg:16,pierce:true,hitIv:.3,life:1.8,home:4,homeR:750,spd:820,trail:'#ffb347',kx:()=>rand(-120,120),ky:-260});sTone(500,1300,.3,.1,'sawtooth');}},
 a_meteor(dt){const st=run.st;if(!st.g&&run.t>=.25){st.g=1;projs.push({k:'giant',img:'fx_a_giant',x:Math.max(100,Math.min(WORLD_W-100,P.x+P.face*260)),y:-260,vy:2600,landed:false,life:SK.a_meteor.dur-.25});sTone(1500,200,.5,.15,'triangle');}},
});
function drawRunExtras(){if(!run)return;const id=chain[run.i],st=run.st;
  if(id==='m_curse'&&st.list){ctx.save();ctx.globalCompositeOperation='lighter';for(const e of st.list){if(e.dead)continue;const ex=e.x,ey=e.y-e.h/2;
      if(ok(IMG.fx_m_sigil)){ctx.save();ctx.translate(ex,GY);ctx.scale(1,.35);ctx.rotate(t0*2);ctx.globalAlpha=.8;ctx.drawImage(IMG.fx_m_sigil,-70,-70,140,140);ctx.restore();}
      ctx.strokeStyle='#b98cff';ctx.lineWidth=3;ctx.globalAlpha=.7;ctx.beginPath();for(let i=0;i<=12;i++){const k=i/12;const x=P.x+(ex-P.x)*k,y=(P.y-90)+(ey-(P.y-90))*k+Math.sin(k*12+t0*14)*8;i?ctx.lineTo(x,y):ctx.moveTo(x,y);}ctx.stroke();}ctx.restore();}
  if(id==='m_drain'&&st.tg){ctx.save();ctx.globalCompositeOperation='lighter';for(const e of st.tg){if(e.dead)continue;const ex=e.x,ey=e.y-e.h/2;for(const [c,w] of [['#7dff9a',6],['#fff',2]]){ctx.strokeStyle=c;ctx.lineWidth=w;ctx.globalAlpha=.7;ctx.beginPath();
      for(let i=0;i<=14;i++){const k=i/14;const x=ex+(P.x-ex)*k,y=ey+((P.y-95)-ey)*k+Math.sin(k*9-t0*18)*10*(1-k);i?ctx.lineTo(x,y):ctx.moveTo(x,y);}ctx.stroke();}
      if(Math.random()<.4)parts.push({x:ex,y:ey,vx:(P.x-ex)*2,vy:((P.y-95)-ey)*2,life:.45,max:.45,col:'#7dff9a',sz:4,g:0});}ctx.restore();}
  if(id==='m_ritual'&&st.x!==undefined&&!st.b&&ok(IMG.fx_m_circle)){const k=Math.min(1,run.t/.5);ctx.save();ctx.globalCompositeOperation='lighter';ctx.translate(st.x,GY-6);ctx.scale(1,.3);ctx.rotate(t0*1.5);ctx.globalAlpha=.85;const z=780*k;ctx.drawImage(IMG.fx_m_circle,-z/2,-z/2,z,z);ctx.restore();
    if(Math.random()<.6)parts.push({x:st.x+rand(-380,380),y:GY,vx:0,vy:rand(-500,-200),life:.6,max:.6,col:'#ff6ad5',sz:rand(3,6),g:0});}}
function ghostOf(){const hf=heroFrame();return{x:P.x,y:P.y,f:P.face,k:hf[0]+hf[1],m:FM[hf[0]][hf[1]],life:.25};}

function tryRelease(){if(scene==='town'){say('ในเมืองปล่อยคอมโบไม่ได้ — ไปที่ประตูวาร์ปทางขวา','#ffd76a');return;}
  if(state!=='play'||run||finale)return;
  if(!chain.length){say('ยังไม่มีคอมโบ กด C เพื่อจัด','#ff8a8a');return;}
  if(energy<100){say('เกจยังไม่เต็ม — ฟันศัตรูเพื่อเติม','#ff8a8a');return;}
  energy=0;eeT=0;P.cnt=null;P.coreA=0;run={i:0,t:0,total:0,hits:0,dmg:0,acc:0,st:{},mult:1,dur:chainTime(),home:P.x};P.inv=0;beginStep();sTone(300,900,.35,.15,'triangle');
}
function beginStep(){const id=chain[run.i],prev=run.i>0?chain[run.i-1]:null;run.t=0;run.st={f0:P.face};run.mult=1;run.syn=null;run.acc=-1;
  for(const s of SYN)if(s[0]===prev&&s[1]===id){run.mult=s[3];run.syn=s[2];if(!found.has(s[2])){found.add(s[2]);save.found=[...found];persist();}
    banner={t:'คอมโบซ่อน! '+s[2]+' ×'+s[3],col:'#ffd76a',life:1.4,max:1.4};sTone(600,1200,.3,.12,'square');}
}
function updateRun(dt){const id=chain[run.i];TICK[id](dt);run.t+=dt;run.total+=dt;
  if(run.t>=SK[id].dur){if(id==='dash'||id==='xslash')P.vx=0;if(id==='spin'||id==='lotus'||id==='a_storm')P.face=run.st.f0;run.i++;
    if(run.i>=chain.length)startFinale();else beginStep();}}

// ================= ฉากจบคอมโบ =================
function startFinale(){TS.fin++;finale={t:0,hits:run.hits,dmg:run.dmg,phase:0,beats:0,slashes:[],queue:[],bonus:0,n:0,home:run.home};run=null;P.vy=Math.max(P.vy,0);P.finisher=9;P.vx=0;
  sTone(220,40,1.4,.3);}
function crackGen(){const cs=[];const cx=W/2,cy=H/2-20;for(let i=0;i<12;i++){let a=i/12*Math.PI*2+rand(-.2,.2),x=cx,y=cy;const pts=[[x,y]];const L=rand(180,520);let d=0;
  while(d<L){const s=rand(20,50);a+=rand(-.45,.45);x+=Math.cos(a)*s;y+=Math.sin(a)*s;d+=s;pts.push([x,y]);
    if(Math.random()<.18){const b=[[x,y]];let ba=a+rand(-1,1),bx=x,by=y;for(let j=0;j<3;j++){bx+=Math.cos(ba)*rand(15,40);by+=Math.sin(ba)*rand(15,40);b.push([bx,by]);}cs.push(b);}}
  cs.push(pts);}return{pts:cs,life:1.8,max:1.8};}
function groundCrack(x){fxs.push({t:'gcrack',x,life:1.2,max:1.2,seg:Array.from({length:7},()=>[rand(-1,1),rand(.4,1)])});}
function updateFinale(rdt){const F=finale;F.t+=rdt;
  if(F.phase===0){timeScale=.1;zoomT=1.48;desatT=.9;darkT=.55;
    if(F.t>F.beats*.55&&F.beats<2){F.beats++;sTone(70,38,.3,.8);sTone(55,30,.35,.5);}
    if(F.t>=1.2){F.phase=1;blackT=.13;sTone(2400,60,.15,.15,'square');}}
  else if(F.phase===1){blackT-=rdt;if(blackT<=0){F.phase=2;F.t2=0;
      P.finisher=0;timeScale=1;zoomT=1;zoom=1.12;desatT=0;desat=0;darkT=0;dark=0;flash=1;shake=36;hitstop=.1;chroma=1;sBoom(.9);
      spr('fx_burst',P.x,P.y-80,820,0,1,.6,1.5);spr('fx_shock',P.x,GY-130,1000,0,1,.75,1.2);ring(P.x,P.y-80,20,700,'#ffd76a',.6,20);
      for(let i=0;i<7;i++)F.slashes.push({at:i*.045,done:false});
      const tg=enemies.filter(e=>!e.dead&&(e.doomed||e.marked)).sort((a,b)=>Math.abs(a.x-P.x)-Math.abs(b.x-P.x));
      const span=.8;tg.forEach((e,i)=>F.queue.push({e,at:.12+(tg.length>1?i*span/(tg.length-1):0)}));}}
  else if(F.phase===2){F.t2+=rdt;
    for(const s of F.slashes)if(!s.done&&F.t2>=s.at){s.done=true;const a=rand(-1.1,1.1),cx=P.x+rand(-260,260),cy=P.y-rand(60,240),L=700;
      line(cx-Math.cos(a)*L,cy-Math.sin(a)*L,cx+Math.cos(a)*L,cy+Math.sin(a)*L,'#fff',rand(14,26),.4);spr('fx_slashG',cx,cy,rand(500,760),a,Math.random()<.5?1:-1,.35,1.1);
      shake=Math.max(shake,22);sSwish();nz(5000,.6,.2,.1,'highpass');}
    for(const q of F.queue)if(!q.done&&F.t2>=q.at){q.done=true;const e=q.e;if(e.dead)continue;
      const b=Math.round((e.doomed?120:60)*atkMul()*(e.heavy?2:1));
      const nf=Math.sign(e.x-P.x)||1;{const g=ghostOf();g.x=e.x-nf*65;g.y=Math.min(GY,e.y);g.f=nf;g.life=.32;trail.push(g);}P.swT=t0-1;
      spr(F.n%2?'fx_slashC':'fx_slashG',e.x,e.y-e.h/2,300,rand(-.6,.6),nf,.25,1.25);sSwish();F.bonus+=b;F.n++;if(e.heavy||F.n%3===1)addText(e.x+rand(-30,30),e.y-e.h-10-rand(0,40),b,false,true);
      spr('fx_burst',e.x,e.y-e.h/2,e.heavy?300:220,rand(0,6),1,.35,1.4);spr('fx_shock',e.x,GY-60,e.heavy?380:260,0,1,.4,1.2);kill(e,true);
      shake=Math.max(shake,14);if(F.n%3===1)sBoom(.35);}
    if(F.t2>1.05&&!F.result){F.result=true;const hits=F.hits+F.n,dmg=F.dmg+F.bonus;
      const rank=hits>=1500?'SSS':hits>=800?'SS':hits>=400?'S':hits>=150?'A':'B';
      bigTotal={hits,dmg,rank,life:3.8,max:3.8};sBoom(.5);sTone(400,1600,.4,.15,'square');}
    if(F.t2>1.5){finale=null;}}
}

// ================= โลก / แมพยาว =================
function makeEnemy(x,type,wander){const T=ET[type];const hp=Math.round(T.hp*hpScale());
  return{type,x,y:T.fly?GY-150:GY,vx:0,vy:0,w:T.w,h:T.h,hp,max:hp,heavy:T.kb<.6,kb:T.kb,speed:rand(T.sp[0],T.sp[1]),hitT:0,stun:0,ground:!T.fly,bob:rand(0,6),home:x,aggro:!wander,wt:rand(0,6),dive:0,cd:rand(1,3),wind:0,acd:rand(.5,1.4),hpLag:hp,brkV:0,brkMax:(T.brk||0)*(1+.12*(stage-1)),broken:0,born:0,lunge:0,tilt:0};}
function populate(){enemies=[];drops=[];for(let x=700;x<WORLD_W-350;x+=rand(420,620)){const n=Math.floor(rand(3,6));for(let i=0;i<n;i++)enemies.push(makeEnemy(x+rand(-120,120),pickType(),true));}
  if(stage>=2)enemies.push(makeEnemy(portalX-260,'golem',true));}
function spawn(dt){spawnT-=dt;if(finale||tut)return;
  const vis=enemies.filter(e=>!e.dead&&!e.doomed&&e.x>camX-500&&e.x<camX+W+500).length;
  const want=run?28:8+stage*2;const iv=Math.max(.25,1.2-.1*stage)/(run?3:1);
  if(spawnT<=0&&vis<want){spawnT=iv;let side=Math.random()<.5?-1:1;let x=side<0?camX-50:camX+W+50;
    if(x<20||x>WORLD_W-20){side=-side;x=side<0?camX-50:camX+W+50;}
    if(x<20||x>WORLD_W-20)return;let t=pickType();if(t==='golem'&&!run&&Math.random()<.6)t='yak';enemies.push(makeEnemy(x,t,false));}}
function updatePlayer(dt){
  P.dodgeAge+=dt;P.dodgeT=Math.max(0,P.dodgeT-dt);P.dodgeCD=Math.max(0,P.dodgeCD-dt);P.ihit=Math.max(0,P.ihit-dt);P.hcT=Math.max(0,P.hcT-dt);
  if(P.dodgeT>0&&P.dodgeAge<.2&&Math.random()<.8)trail.push(Object.assign(ghostOf(),{life:.3,dodge:1}));
  if(P.cnt)updateCounter(dt);if(P.coreA>0){updateCore(dt);P.coreA-=dt;}
  const busy=(run&&((chain[run.i]==='dash'&&run.t<.33)||(chain[run.i]==='xslash'&&run.t<.3)))||(P.dodgeT>0&&P.dodgeAge<.2)||P.cnt||(P.coreA>0&&cls==='sword');
  let mv=(keys.right?1:0)-(keys.left?1:0);if(P.finisher>0||(finale&&!finale.result)||P.cnt)mv=0;
  if(!busy){const tgt=mv*340*spdMul();P.vx+=(tgt-P.vx)*Math.min(1,dt*14);if(mv&&!(run&&['spin','lotus','a_storm'].includes(chain[run.i])))P.face=mv;}
  const wasG=P.ground;P.vy+=1900*dt;P.x+=P.vx*dt;P.y+=P.vy*dt;
  if(P.y>=GY){P.y=GY;if(!wasG&&P.vy>300)P.land=.14;P.vy=0;P.ground=true;}else P.ground=false;
  P.x=Math.max(24,Math.min(WORLD_W-24,P.x));
  P.jt=Math.max(0,(P.jt||0)-dt);if(P.ground&&Math.abs(P.vx)>200){P.fs=(P.fs||0)-dt;if(P.fs<=0){P.fs=.16;for(let i=0;i<3;i++)parts.push({x:P.x-P.face*14+rand(-6,6),y:GY,vx:-P.vx*.15+rand(-40,40),vy:rand(-90,-20),life:.4,max:.4,col:'rgba(190,170,150,.8)',sz:rand(3,6),g:150,solid:1});}}
  P.inv=Math.max(0,P.inv-dt);P.hurt=Math.max(0,P.hurt-dt);P.land=Math.max(0,P.land-dt);P.atkA=Math.max(0,P.atkA-dt);
  if(run&&chain[run.i]!=='dash'&&chain[run.i]!=='xslash'){if(Math.random()<.5)trail.push(ghostOf());}
  for(const t of trail)t.life-=dt;trail=trail.filter(t=>t.life>0);if(trail.length>14)trail.splice(0,trail.length-14);
  P.atkCD-=dt;P.swing=Math.max(0,P.swing-dt);
  if(keys.atk&&P.atkCD<=0&&!run&&!finale&&P.finisher<=0&&!P.cnt&&P.coreA<=0&&cls!=='sword'){P.atkA=P.atkMax=.24;P.swing=.1;
    if(cls==='archer'){P.atkCD=.26;{const v=aimAt(P.x+P.face*50,P.y-80,1250,P.face);bullet({img:'fx_a_arrow',x:P.x+P.face*50,y:P.y-80,vx:v[0],vy:v[1],sz:110,r:28,dmg:11,life:.7,kx:P.face*130,ky:-80,hs:1});}sTwang();}
    else{P.atkCD=.32;bullet({img:'fx_m_orb',x:P.x+P.face*60,y:P.y-80,vx:aimAt(P.x+P.face*60,P.y-80,720,P.face)[0],vy:aimAt(P.x+P.face*60,P.y-80,720,P.face)[1],dmg:15,life:.8,r:30,home:2.5,homeR:420,boom:{r:60,d:6},kx:P.face*140,ky:-120,sz:120,trail:'#7ad7ff',hs:1});sMagic(520);}}
  // นักดาบ: ฟัน 4 จังหวะ (ฟันลง → ฟันกลับ → แทงพุ่ง → เสยลอย) + ฟันกลางอากาศ
  if(keys.atk&&P.atkCD<=0&&!run&&!finale&&P.finisher<=0&&!P.cnt&&P.coreA<=0&&cls==='sword'){
    if(!P.ground){P.atkCD=.17;P.airAtk=1;P.swing=.12;P.atkA=P.atkMax=.2;P.vy=Math.min(P.vy,-60);const a=rand(-.3,.3);
      arc(P.x+P.face*30,P.y-80,90,-2.2,1.4,'#e6f0ff',12,.16,P.face);spr('fx_slashG',P.x+P.face*60,P.y-80,230,a+1,P.face,.16,1.2);sSwish();
      const n=front(160,170,13,P.face*120,-260);if(n){hitstop=Math.max(hitstop,.04);shake=Math.max(shake,3);}}
    else{if(t0-(P.lastAtk||0)>.55)P.atkStep=-1;P.lastAtk=t0;P.airAtk=0;P.atkStep=(P.atkStep+1)%4;const st=P.atkStep,big=st===3,thr=st===2;
    P.atkCD=big?.3:thr?.22:.19;P.swing=.12;P.atkA=P.atkMax=big?.32:thr?.24:.21;
    P.vx+=P.face*(big?200:thr?420:120);
    if(thr){line(P.x+P.face*20,P.y-80,P.x+P.face*230,P.y-80,'#fff',10,.14);line(P.x+P.face*30,P.y-80,P.x+P.face*210,P.y-80,'#9fd8ff',22,.12);spr('fx_slashC',P.x+P.face*150,P.y-80,200,0,P.face,.14,1.3);}
    else arc(P.x+P.face*28,P.y-78,big?100:76,big?1.6:(st?1.2:-1.2),big?-1.6:(st?-1.1:1.1),big?'#fff':'#dfe8ff',big?16:9,.17,P.face);
    if(!thr)spr('fx_slashG',P.x+P.face*(big?70:58),P.y-(big?100:82),big?280:190,[0,.7,0,-1.2][st],P.face,big?.22:.15,1.2);sSwish();
    const n=thr?front(230,110,15,P.face*260,-60):front(big?160:130,big?180:130,big?24:12,P.face*(big?160:150),big?-680:-90);
    if(big){P.vy=-380;P.ground=false;}
    if(n){hitstop=Math.max(hitstop,big?.085:thr?.055:.045);shake=Math.max(shake,big?8:thr?5:3);if(big||thr)punch=Math.max(punch,big?.04:.02);}}}
  if(P.finisher>0)P.finisher-=dt;
  // ประตูวาร์ป
  if(scene==='town'){if(Math.abs(P.x-portalX)<50){save.chain=chain;saveEq();startStage();}}
  else if(!tut&&kills>=quota&&!run&&!finale&&!bigTotal&&Math.abs(P.x-portalX)<60)stageClear();
}
function updateEnemies(dt){
  for(const e of enemies){if(e.dead)continue;const T=ET[e.type];
    e.hitT-=dt;e.stun-=dt;
    const flying=T.fly&&!e.doomed&&e.stun<=0;
    if(flying){e.dive=Math.max(0,e.dive-dt);e.cd-=dt;if(e.aggro&&e.cd<=0&&Math.abs(P.x-e.x)<260){e.dive=.9;e.cd=rand(2,3.5);}
      const ty=e.dive>0?GY-15:GY-150+Math.sin(t0*2+e.bob)*25;e.vy+=((ty-e.y)*6-e.vy)*Math.min(1,dt*5);}
    else e.vy+=(e.doomed?950:1900)*dt;
    e.x+=e.vx*dt;e.y+=e.vy*dt;
    if(e.y>=GY){e.y=GY;if(e.vy>500&&e.doomed){e.vy=-e.vy*.35;}else e.vy=0;e.ground=true;}else e.ground=false;
    if(!e.aggro&&Math.abs(P.x-e.x)<430)e.aggro=true;
    if(e.broken>0){e.broken-=dt;e.stun=Math.max(e.stun,.1);e.wind=0;if(e.broken<=0){e.broken=0;e.brkV=0;}}
    e.hpLag+=(e.hp-e.hpLag)*Math.min(1,dt*(e.hp<e.hpLag?2.5:20));e.born+=dt;e.tilt*=Math.pow(.004,dt);
    if(e.lunge>0){e.lunge-=dt;if(T.lunge&&e.stun<=0)e.x+=e.ldir*T.lunge*dt*Math.max(0,e.lunge/.22)*1.6;}
    // ท่าโจมตีมีจังหวะง้าง (มองเห็นก่อนโดน) — หลบตอนแสงวาบ = หลบเฉียดฉิว
    if(e.wind>0){if(e.doomed||run||finale||(e.stun>0&&!T.armor)){e.wind=0;}else{e.wind-=dt;if(e.wind<=0){e.wind=0;e.acd=e.heavy?rand(1.6,2.6):rand(1,1.9);enemyStrike(e);}}}
    else{e.acd-=dt;if(!T.fly&&e.aggro&&!run&&!finale&&P.finisher<=0&&!e.doomed&&e.stun<=0&&!(e.broken>0)&&e.acd<=0&&Math.abs(e.x-P.x)<e.w/2+(T.reach||30)+30&&Math.abs((e.y-e.h/2)-(P.y-70))<Math.max(90,e.h/2+40)){
      e.wind=e.windMax=T.wind*(e.type==='ghost'&&stage>3?.85:1);e.wface=Math.sign(P.x-e.x)||1;if(e.heavy)osc('sawtooth',90,180,.3,.08,.2);}}
    if((e.ground||flying)&&(e.stun>0||e.doomed||(e.wind>0&&!T.fly)))e.vx*=Math.pow(.02,dt);
    else if((e.ground||flying)&&!e.doomed){let tv;if(e.aggro)tv=Math.sign(P.x-e.x)*e.speed*(e.dive>0?1.6:1);else{e.wt+=dt;tv=Math.sin(e.wt*.8)*e.speed*.4+(e.home-e.x)*.6;}
      e.vx+=(tv-e.vx)*Math.min(1,dt*6);}
    e.x=Math.max(10,Math.min(WORLD_W-10,e.x));
    // ปักษาไฟโฉบลงมาชน (การโฉบคือสัญญาณเตือน)
    if(T.fly&&e.dive>0&&!run&&!finale&&P.finisher<=0&&!e.doomed&&e.stun<=0&&Math.abs(e.x-P.x)<e.w/2+14&&Math.abs((e.y-e.h/2)-(P.y-70))<Math.max(70,e.h/2+20)){e.dive=0;enemyStrike(e);}
  }
  enemies=enemies.filter(e=>!e.dead);
  // ของดรอป
  for(const d of drops){d.t+=dt;d.vy+=1400*dt;d.x+=d.vx*dt;d.y+=d.vy*dt;if(d.y>=GY-18){d.y=GY-18;d.vy=-d.vy*.3;d.vx*=.7;}
    const dx=P.x-d.x,dd=Math.abs(dx);if(d.t>.4&&(dd<170||(!run&&!finale&&bigTotal&&dd<700))){d.x+=Math.sign(dx)*Math.min(dd,(dd<170?520:900)*dt);}
    if(d.t>.4&&dd<34&&Math.abs((P.y-60)-d.y)<120){d.got=1;if(d.stone){stones++;saveEq();pickups.push({stone:1,life:2.2,max:2.2});sTone(660,1980,.25,.15,'triangle');sparks(d.x,d.y,'#b98cff',14,320);}else{gainItem(d.it);sTone(880,1760,.15,.12,'triangle');sparks(d.x,d.y,RAR[d.it.r].c,10,300);}}}
  drops=drops.filter(d=>!d.got);
}
function updateProjs(dt){
  for(const p of projs){
    if(p.k==='wave'){p.x+=p.vx*dt;p.life-=dt;for(const e of enemies){if(e.dead||p.hit.has(e))continue;if(Math.abs(e.x-p.x)<50&&Math.abs((e.y-e.h/2)-p.y)<80){p.hit.add(e);damage(e,16,Math.sign(p.vx)*280,-280);}}if(p.x<camX-200||p.x>camX+W+200)p.life=0;}
    else if(p.k==='sword'){p.y+=p.vy*dt;if(p.y>=GY-6){p.life=0;hitRect(p.x-36,GY-140,72,140,11,()=>rand(-60,60),-400);ring(p.x,GY-4,4,46,p.col,.2,4);
      for(let i=0;i<4;i++)parts.push({x:p.x,y:GY,vx:rand(-200,200),vy:rand(-300,-80),life:.3,max:.3,col:p.col,sz:2,g:1200});}else p.life=1;}
    else if(p.k==='naga'){p.t+=dt;p.life-=dt;p.x+=p.vx*dt;p.y=p.by+Math.sin(p.t*9)*22;
      for(const e of enemies){if(e.dead)continue;if(Math.abs(e.x-p.x)<120&&Math.abs((e.y-e.h/2)-p.y)<95){const l=p.last.get(e)||-9;if(p.t-l>.15){p.last.set(e,p.t);damage(e,14,Math.sign(p.vx)*220,-300);}}}
      for(let i=0;i<3;i++)parts.push({x:p.x-Math.sign(p.vx)*rand(40,150),y:p.y+rand(-30,30),vx:-p.vx*.15,vy:rand(-160,-40),life:.45,max:.45,col:['#ff7a3d','#ffcf4a','#ff3d1f'][i],sz:rand(4,8),g:-150});}
    else if(p.k==='chakra'){p.t+=dt;p.life-=dt;if(p.t<.9){const k=p.t/.9;p.x=p.x0+p.dir*720*(1-(1-k)*(1-k));}else{const d=P.x-p.x;p.x+=Math.sign(d)*Math.min(Math.abs(d),1150*dt);if(Math.abs(d)<30&&p.t>1)p.life=0;}
      p.y+=((P.y-85)-p.y)*Math.min(1,dt*4);
      for(const e of enemies){if(e.dead)continue;if(Math.abs(e.x-p.x)<80&&Math.abs((e.y-e.h/2)-p.y)<90){const l=p.last.get(e)||-9;if(p.t-l>.08){p.last.set(e,p.t);damage(e,9,Math.sign(e.x-p.x||1)*120,-200);}}}
      if(Math.random()<.5)sparks(p.x,p.y,'#ffe066',1,200);}
    else if(p.k==='clone'){p.life-=dt;p.cd-=dt;if(p.cd<=0){p.cd=rand(.18,.28);const c=near(650);
        if(c.length){const e=c[Math.floor(Math.random()*c.length)];p.face=Math.random()<.5?1:-1;p.x=e.x-p.face*60;p.f=(p.f+1)%3;
          damage(e,12,p.face*160,-260);spr(Math.random()<.5?'fx_slashC':'fx_slashG',e.x,e.y-e.h/2,180,rand(-.5,.5),p.face,.16,1.2);sSwish();
          for(let i=0;i<6;i++)parts.push({x:p.x,y:GY-rand(10,140),vx:rand(-80,80),vy:rand(-80,0),life:.3,max:.3,col:'#b18cff',sz:3,g:0});}}}
    else if(p.k==='b')updateBullet(p,dt);
    else if(p.k==='giant'){p.life-=dt;if(!p.landed){p.y+=p.vy*dt;if(p.y>=GY-210){p.y=GY-210;p.landed=true;
        hitCircle(p.x,GY-60,300,80,outward(520,p.x),-760,{air:true});spr('fx_shock',p.x,GY-80,760,0,1,.6,1.25);spr('fx_burst',p.x,GY-60,520,0,1,.4,1.4);
        ring(p.x,GY-6,20,420,'#fff1a8',.5,16);groundCrack(p.x);flash=.6;shake=30;hitstop=.13;sBoom(.9);
        for(let i=0;i<40;i++)parts.push({x:p.x+rand(-80,80),y:GY,vx:rand(-800,800),vy:rand(-700,-150),life:.8,max:.8,col:'#a98b6a',sz:rand(4,9),g:1500,solid:1});}}}
  }
  projs=projs.filter(p=>p.life>0);
}
function updateFx(dt){
  for(const f of fxs){f.life-=dt;if(f.t==='corpse'){f.vy+=1900*dt;f.x+=f.vx*dt;f.y+=f.vy*dt;f.rot+=f.vr*dt;if(f.y>GY){f.y=GY;f.vy*=-.3;f.vx*=.5;f.vr*=.5;}}}fxs=fxs.filter(f=>f.life>0);
  for(const p of parts){p.vy+=p.g*dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.life-=dt;if(p.vr)p.rot+=p.vr*dt;if(p.solid&&p.y>GY+4){p.y=GY+4;p.vy*=-.3;p.vx*=.6;}}parts=parts.filter(p=>p.life>0);
  if(parts.length>1100)parts.splice(0,parts.length-1100);
  for(const t of texts){t.y+=t.vy*dt;t.vy*=Math.pow(.15,dt);t.life-=dt;}texts=texts.filter(t=>t.life>0);
  if(texts.length>160)texts.splice(0,texts.length-160);
}
function update(rdt){
  t0+=rdt;
  if(finale&&state==='play')updateFinale(rdt);
  zoom+=(zoomT-zoom)*Math.min(1,rdt*7);desat+=(desatT-desat)*Math.min(1,rdt*7);dark+=(darkT-dark)*Math.min(1,rdt*6);
  flash=Math.max(0,flash-rdt*2.6);critCD-=rdt;critFl=Math.max(0,critFl-rdt*2.5);shake=Math.max(0,shake-rdt*55);chroma=Math.max(0,chroma-rdt*1.6);
  if(cracks){cracks.life-=rdt;if(cracks.life<=0)cracks=null;}
  for(const o of [bigTotal,banner,toast])if(o)o.life-=rdt;for(const p of pickups)p.life-=rdt;goldT=Math.max(0,goldT-rdt);pickups=pickups.filter(p=>p.life>0);
  if(bigTotal&&bigTotal.life<=0)bigTotal=null;if(banner&&banner.life<=0)banner=null;if(toast&&toast.life<=0)toast=null;
  if(mus){const c=state!=='play'||scene==='town';if(c!==mus.calm)mus.calm=c;const want=muted||!musicOn?0:(finale&&finale.phase<2?.03:(c?.12:.16));if(Math.abs((mus.want||0)-want)>.001){mus.want=want;mus.bus.gain.setTargetAtTime(want,T(),.25);}}
  // กล้องตามตัวละคร
  camLead+=(P.face*110-camLead)*Math.min(1,rdt*2.5);const tx=Math.max(0,Math.min(WORLD_W-W,P.x-W/2+camLead));camX+=(tx-camX)*(1-Math.exp(-rdt*6));
  for(const l of lights)l.life-=rdt;lights=lights.filter(l=>l.life>0);punch=Math.max(0,punch-rdt);updateMotes(rdt);
  if(state!=='play')return;
  if(hitstop>0){hitstop-=rdt;return;}
  if(eeT>0){eeT-=rdt;if(eeT<=0){eeT=0;eeSrc=null;}}
  const dt=rdt*timeScale*(tutAssist()?.25:1),edt=dt*(eeT>0&&!finale?.14:1);
  updatePlayer(dt);if(run)updateRun(dt);updateEnemies(edt);updateProjs(dt);updateFx(dt);if(scene==='stage')spawn(edt);
  if(tut)updateTut(rdt,dt);
  if(P.hp<=0&&tut){P.hp=P.maxHp;say('บทสอนไม่ตายจริง — ฟื้นเลือดให้แล้ว ลองใหม่!','#ffd76a',2);}
  if(P.hp<=0){P.hp=0;saveEq();openHub('💀 แพ้แล้ว — เงินและของที่เก็บได้ยังอยู่ครบ ลองซื้อของหรือตีบวกแล้วลุยด่าน '+stage+' ใหม่');}
}

// ================= วาด =================
const STAGEBG=[['bg','วัดยามพลบค่ำ'],['bg_forest','ป่าไผ่หมอกจันทร์'],['bg_ruins','เมืองโบราณร้าง'],['bg_sky','วิมานหิมพานต์']];
const stageBg=()=>STAGEBG[Math.floor((stage-1)/2)%STAGEBG.length];
function drawBG(){let im=scene==='town'?IMG.town:IMG[stageBg()[0]];if(!ok(im))im=IMG.bg;if(!ok(im)){ctx.fillStyle='#24142e';ctx.fillRect(0,0,W,H);return;}
  const sw=im.naturalWidth,sh=im.naturalHeight,fy=sh/H;
  const tile=(off,sy,hh)=>{let i0=Math.floor(off/W);for(let i=i0;i<i0+2;i++){const x=i*W-off;ctx.save();
      if(((i%2)+2)%2){ctx.translate(x+W,0);ctx.scale(-1,1);ctx.drawImage(im,0,sy*fy,sw,hh*fy,0,sy,W,hh);}else ctx.drawImage(im,0,sy*fy,sw,hh*fy,x,sy,W,hh);ctx.restore();}};
  const sc=1.3,fw=W*sc,fh=H*sc,par=(fw-W)*Math.min(1,camX/Math.max(1,WORLD_W-W));ctx.drawImage(im,0,0,sw,sh,-par,H-fh,fw,fh);tile(camX,398,H-398);
  const g=ctx.createLinearGradient(0,388,0,412);g.addColorStop(0,'rgba(20,10,30,0)');g.addColorStop(.5,'rgba(20,10,30,.45)');g.addColorStop(1,'rgba(20,10,30,0)');ctx.fillStyle=g;ctx.fillRect(0,388,W,24);}
function drawPortal(){const x=portalX,on=scene==='town'||kills>=quota;const y=GY-95;
  ctx.save();ctx.translate(x,y);
  ctx.globalCompositeOperation='lighter';
  for(let i=0;i<3;i++){ctx.save();ctx.rotate(t0*(i%2?-1.4:1.1)+i);ctx.strokeStyle=on?['#ffd76a','#ff8fc8','#9ef'][i]:'#555';ctx.globalAlpha=on?.8:.35;ctx.lineWidth=6-i;
    ctx.beginPath();ctx.ellipse(0,0,58+i*10,92+i*8,0,0,Math.PI*1.6);ctx.stroke();ctx.restore();}
  if(on){const g=ctx.createRadialGradient(0,0,5,0,0,90);g.addColorStop(0,'rgba(255,240,200,.9)');g.addColorStop(1,'rgba(160,80,255,0)');ctx.fillStyle=g;ctx.beginPath();ctx.ellipse(0,0,60,95,0,0,7);ctx.fill();}
  ctx.restore();
  if(!on)txt('กำจัดอีก '+(quota-kills)+' ตัว',x,y-115,14,'#ccc','center',700);else txt(scene==='town'?'ออกเดินทาง ด่าน '+stage+' →':'↓ ประตูวาร์ป',x,y-115+Math.sin(t0*5)*4,16,'#ffd76a');}
function drawPlayer(sil){const p=P;
  const [fk,fi]=heroFrame(),m=FM[fk][fi],im=IMG[fk+fi],key=fk+fi;
  if(key!==p.curKey){p.prevKey=p.curKey;p.prevM=p.curM;p.prevF=p.face;p.curKey=key;p.curM=m;p.swT=t0;}
  if(sil){ctx.save();ctx.translate(p.x,p.y);ctx.scale(p.face,1);ctx.drawImage(tint(im,'#ffffff'),-m.w*m.ax,-m.h,m.w,m.h);ctx.restore();return;}
  ctx.fillStyle='rgba(0,0,0,.4)';ctx.beginPath();ctx.ellipse(p.x,GY+2,34,8,0,0,7);ctx.fill();
  if(p.ihit>0&&!run&&p.hurt<=0&&Math.floor(p.ihit*20)%2)return;
  const col=run?SK[chain[run.i]].col:(p.finisher>0?'#ffd76a':null);
  if(col){ctx.save();ctx.globalCompositeOperation='lighter';const g=ctx.createRadialGradient(p.x,p.y-75,8,p.x,p.y-75,130);g.addColorStop(0,col);g.addColorStop(1,'rgba(0,0,0,0)');
    ctx.globalAlpha=.32+.15*Math.sin(t0*20);ctx.fillStyle=g;ctx.fillRect(p.x-140,p.y-210,280,250);ctx.restore();}
  if(trail.length){ctx.save();ctx.globalCompositeOperation='lighter';for(const t of trail){ctx.globalAlpha=t.life/.25*.35;ctx.save();ctx.translate(t.x,t.y);ctx.scale(t.f,1);ctx.drawImage(tint(IMG[t.k],col||'#9ef'),-t.m.w*t.m.ax,-t.m.h,t.m.w,t.m.h);ctx.restore();}ctx.restore();}
  ctx.save();ctx.translate(p.x,p.y);
  let sy=1,sx=1;
  if(fk.endsWith('_run')&&fi<2&&p.ground)sy=1+.014*Math.sin(t0*4);
  if(p.land>0){const k=p.land/.14;sy*=1-.13*k;sx*=1+.1*k;}
  if(p.swing>0){sx*=1.05;sy*=.97;}
  if(p.jt>0){const k=p.jt/.14;sy*=1+.14*k;sx*=1-.1*k;}
  ctx.rotate((p.ground?Math.max(-1,Math.min(1,p.vx/340))*.06:Math.max(-1,Math.min(1,p.vy/900))*-.05*p.face));
  ctx.scale(sx,sy);
  // ซ้อนเฟรมก่อนหน้าจางๆ ให้ท่าต่อกันเนียนขึ้น
  const b=Math.min(1,(t0-p.swT)/.12);
  if(b<1&&p.prevKey&&IMG[p.prevKey]){ctx.save();ctx.scale(p.prevF,1);ctx.globalAlpha=(1-b)*(1-b)*.8;const pm=p.prevM;ctx.drawImage(IMG[p.prevKey],-pm.w*pm.ax,-pm.h,pm.w,pm.h);ctx.restore();}
  ctx.scale(p.face,1);
  ctx.drawImage(im,-m.w*m.ax,-m.h,m.w,m.h);
  if(p.hurt>0){ctx.globalAlpha=.5;ctx.drawImage(tint(im,'#ff3040'),-m.w*m.ax,-m.h,m.w,m.h);}
  ctx.restore();}
function drawEnemy(e,sil){const T=ET[e.type];
  const moving=(T.fly||e.ground)&&e.stun<=0&&!e.doomed&&(Math.abs(e.vx)>8||T.fly||T.hover);const fi=moving?Math.floor(t0*T.fps+e.bob)%4:0;const m=FM[T.fk][fi],im=IMG[T.fk+fi],w=m.w,h=m.h;
  const tx=(e.aggro?P.x:e.x+e.vx)-e.x;if(e.face===undefined)e.face=Math.sign(tx)||1;if(Math.abs(tx)>26&&e.wind<=0&&!(e.lunge>0))e.face=Math.sign(tx);const d=e.face;e.fx=(e.fx===undefined?d:e.fx+(d-e.fx)*.35);const hover=T.hover?-10+Math.sin(t0*5+e.bob)*5:0;
  if(e.cfi!==fi){e.pfi=e.cfi;e.sw=t0;e.cfi=fi;}
  if(!sil){const sh=T.fly?Math.max(.25,1-(GY-e.y)/260):1;ctx.fillStyle=`rgba(0,0,0,${.35*sh})`;ctx.beginPath();ctx.ellipse(e.x,GY+2,e.w*.6*sh,6*sh,0,0,7);ctx.fill();}
  ctx.save();const bk=Math.min(1,e.born/.35);ctx.translate(e.x+(e.hitT>0?rand(-3,3):0),e.y+hover+(1-bk)*30);if(bk<1)ctx.globalAlpha=bk;
  if(e.tilt)ctx.rotate(e.tilt*.6);
  if(!e.ground&&!(T.fly&&e.stun<=0&&!e.doomed))ctx.rotate((e.vx>0?1:-1)*Math.min(1,Math.abs(e.vy)/900)*.7);
  if(T.fly&&e.dive>0)ctx.rotate(-d*.35);
  const wk=e.wind>0&&e.windMax?1-e.wind/e.windMax:0;
  if(wk>0){const ln=T.lean||.16;ctx.rotate(-(e.wface||d)*ln*Math.sin(wk*Math.PI*.5));if(T.pound)ctx.scale(1-.06*wk,1+.12*wk);else ctx.scale(1+.07*wk,1-.05*wk);}
  if(e.lunge>0){const lk=e.lunge/.22;if(T.pound)ctx.scale(1+.18*lk,1-.2*lk);else{ctx.rotate(e.ldir*.22*lk);ctx.scale(1+.16*lk,1-.08*lk);}}
  if(!moving&&e.ground&&!T.fly&&!e.doomed&&!(e.broken>0)&&wk<=0)ctx.scale(1,1+.022*Math.sin(t0*3+e.bob));
  if(e.broken>0){const fd=Math.sign(e.x-P.x)||1;ctx.rotate(fd*1.25*Math.min(1,(3.5-e.broken)/.3));}
  ctx.scale(-Math.sign(e.fx||1)*Math.max(.6,Math.abs(e.fx)),1);if(e.ground&&moving&&!T.fly&&!T.hover)ctx.scale(1,1+.03*Math.sin(t0*T.fps*1.6+e.bob));
  if(sil){ctx.drawImage(tint(im,'#ff1030'),-w*m.ax,-h,w,h);ctx.restore();return;}
  {const cb=Math.min(1,(t0-(e.sw||0))/.1);if(cb<1&&e.pfi!==undefined&&!e.doomed&&e.hitT<=0){const pm2=FM[T.fk][e.pfi];ctx.globalAlpha=(1-cb)*.7;ctx.drawImage(IMG[T.fk+e.pfi],-pm2.w*pm2.ax,-pm2.h,pm2.w,pm2.h);ctx.globalAlpha=1;}}
  let src=im,ov=null,ova=.6;if(e.doomed)ov=tint(im,Math.floor(t0*24)%2?'#ffffff':'#ff2a4a');else if(e.hitT>0){ov=tint(im,'#ffffff');ova=e.broken>0?.45:.8;}
  if(e.hitT>0&&!e.doomed){const k=1+e.hitT*1.2;ctx.scale(k,2-k);}
  ctx.drawImage(src,-w*m.ax,-h,w,h);if(ov){ctx.globalAlpha=ova;ctx.drawImage(ov,-w*m.ax,-h,w,h);ctx.globalAlpha=1;}
  if(wk>0){ctx.globalCompositeOperation='lighter';ctx.globalAlpha=.15+.45*wk*(.75+.25*Math.sin(t0*40));ctx.drawImage(tint(im,'#ff2030'),-w*m.ax,-h,w,h);ctx.globalAlpha=1;ctx.globalCompositeOperation='source-over';}
  ctx.restore();
  if(wk>0&&e.wind<=perfWin()){const gx=e.x+(e.wface||d)*e.w*.25,gy=e.y-e.h*.8,gk=e.wind/perfWin(),z=18+40*(1-gk);
    ctx.save();ctx.globalCompositeOperation='lighter';ctx.translate(gx,gy);ctx.rotate(t0*3);ctx.fillStyle='#fff7c0';ctx.globalAlpha=.9;
    for(let i=0;i<4;i++){ctx.rotate(Math.PI/2);ctx.beginPath();ctx.moveTo(0,-z);ctx.lineTo(z*.12,0);ctx.lineTo(0,z*.12);ctx.lineTo(-z*.12,0);ctx.fill();}
    const g=ctx.createRadialGradient(0,0,1,0,0,z*.8);g.addColorStop(0,'rgba(255,240,180,.9)');g.addColorStop(1,'rgba(255,60,40,0)');ctx.fillStyle=g;ctx.beginPath();ctx.arc(0,0,z*.8,0,7);ctx.fill();ctx.restore();}
  else if(wk>0&&e.heavy){txt('!',e.x,e.y-e.h-30-6*wk,26+10*wk,'#ff4050','center',900);}
  if(e.broken>0){for(let i=0;i<3;i++){const a=t0*5+i*2.1;txt('★',e.x+Math.cos(a)*30,e.y-e.h*.55+Math.sin(a)*8-40,14,'#ffe066','center',900);}}
  if(e.hp<e.max&&!e.doomed){const bw=e.type==='golem'?80:44,y=e.y+hover-h-8;ctx.fillStyle='#000a';ctx.fillRect(e.x-bw/2,y,bw,5);ctx.fillStyle='#fff';ctx.fillRect(e.x-bw/2,y,bw*Math.max(0,Math.min(1,e.hpLag/e.max)),5);ctx.fillStyle='#ff4d5e';ctx.fillRect(e.x-bw/2,y,bw*Math.max(0,e.hp/e.max),5);}
  if(e.brkMax&&!e.doomed&&(e.brkV>0||e.broken>0)){const bw=e.type==='golem'?80:44,y=e.y+hover-h-1;ctx.fillStyle='#000a';ctx.fillRect(e.x-bw/2,y,bw,4);ctx.fillStyle=e.broken>0?(Math.floor(t0*10)%2?'#fff':'#7ff3ff'):'#5fd8ff';ctx.fillRect(e.x-bw/2,y,bw*(e.broken>0?e.broken/3.5:Math.min(1,e.brkV/e.brkMax)),4);}
  if(e.type==='golem'&&!e.doomed)txt(T.name,e.x,e.y-h-16,12,'#e8e2d8','center',700);
}
function drawDrops(){for(const d of drops){if(d.stone){ctx.save();ctx.translate(d.x,d.y+Math.sin(t0*4+d.x)*3);ctx.globalCompositeOperation='lighter';const g=ctx.createRadialGradient(0,0,2,0,0,40);g.addColorStop(0,'rgba(185,140,255,.7)');g.addColorStop(1,'rgba(0,0,0,0)');ctx.fillStyle=g;ctx.fillRect(-40,-40,80,80);ctx.globalCompositeOperation='source-over';if(ok(IMG.ui_stone))ctx.drawImage(IMG.ui_stone,-18,-18,36,36);ctx.restore();continue;}
  const R=RAR[d.it.r],im=IMG[iicon(d.it)];const bob=Math.sin(t0*4+d.x)*3;
  if(d.it.r>0){ctx.save();ctx.globalCompositeOperation='lighter';const g=ctx.createLinearGradient(0,d.y-160,0,d.y);g.addColorStop(0,'rgba(0,0,0,0)');g.addColorStop(1,R.c);ctx.globalAlpha=.35+.15*Math.sin(t0*6);ctx.fillStyle=g;ctx.fillRect(d.x-10,d.y-160,20,160);ctx.restore();}
  ctx.save();ctx.translate(d.x,d.y+bob);ctx.shadowColor=R.c;ctx.shadowBlur=14;if(ok(im))ctx.drawImage(im,-19,-19,38,38);ctx.restore();}}
function drawVortex(){if(!run||chain[run.i]!=='vortex'||!run.st.v||run.st.b)return;const st=run.st;const k=Math.min(1,run.t/.4);
  ctx.save();ctx.translate(st.cx,st.cy);
  const g=ctx.createRadialGradient(0,0,4,0,0,170*k);g.addColorStop(0,'rgba(5,0,15,.95)');g.addColorStop(.5,'rgba(40,10,80,.6)');g.addColorStop(1,'rgba(40,10,80,0)');ctx.fillStyle=g;ctx.beginPath();ctx.arc(0,0,170*k,0,7);ctx.fill();
  ctx.globalCompositeOperation='lighter';ctx.lineCap='round';
  for(let i=0;i<7;i++){ctx.save();ctx.rotate(t0*(5+i*.6)+i);ctx.strokeStyle=i%2?'#9a6bff':'#e2d0ff';ctx.globalAlpha=.6;ctx.lineWidth=5-i*.5;ctx.beginPath();ctx.arc(0,0,(40+i*22)*k,0,1.9);ctx.stroke();ctx.restore();}
  ctx.restore();}
function drawFx(){
  ctx.lineCap='round';
  for(const f of fxs){const k=f.life/f.max;ctx.globalAlpha=Math.min(1,k*1.4);
    if(f.t==='arc'){ctx.save();ctx.translate(f.x,f.y);ctx.scale(f.face,1);
      ctx.lineCap='round';ctx.globalCompositeOperation='lighter';ctx.strokeStyle=f.col;ctx.lineWidth=f.w*k*2.6;ctx.globalAlpha*=.28*k;ctx.beginPath();ctx.arc(0,0,f.r,f.a0,f.a1,f.a1<f.a0);ctx.stroke();ctx.restore();}
    else if(f.t==='ring'){const r=f.r1+(f.r0-f.r1)*k;ctx.strokeStyle=f.col;ctx.lineWidth=f.w*k;ctx.beginPath();ctx.ellipse(f.x,f.y,r,r*(f.y>GY-30?.3:1),0,0,7);ctx.stroke();}
    else if(f.t==='bolt'){ctx.strokeStyle=f.col;ctx.lineWidth=7*k;ctx.beginPath();f.pts.forEach((p,i)=>i?ctx.lineTo(p[0],p[1]):ctx.moveTo(p[0],p[1]));ctx.stroke();ctx.strokeStyle='#fff';ctx.lineWidth=2.5;ctx.stroke();}
    else if(f.t==='spr'){const im=IMG[f.name];if(!ok(im))continue;const sz=f.size*(1+(f.grow-1)*(1-k));ctx.save();ctx.globalCompositeOperation='lighter';ctx.globalAlpha=f.alpha*Math.min(1,k*1.8);ctx.translate(f.x,f.y);ctx.scale(f.flip,1);ctx.rotate(f.rot);ctx.drawImage(im,-sz/2,-sz/2,sz,sz);ctx.restore();}
    else if(f.t==='corpse'){const im=IMG[f.k];if(!ok(im))continue;const m=f.m,sc=.7+.3*k;ctx.save();ctx.translate(f.x,f.y-m.h*.4);ctx.rotate(f.rot);ctx.scale(-f.fx*sc,sc);ctx.globalAlpha=Math.min(1,k*1.6);
      ctx.drawImage(im,-m.w*m.ax,-m.h*.6,m.w,m.h);ctx.globalCompositeOperation='lighter';ctx.globalAlpha=(1-k)*.9;ctx.drawImage(tint(im,'#ffffff'),-m.w*m.ax,-m.h*.6,m.w,m.h);ctx.restore();
      if(Math.random()<.5)parts.push({x:f.x+rand(-20,20),y:f.y-rand(10,m.h*.7),vx:rand(-40,40),vy:rand(-160,-60),life:.4,max:.4,col:'rgba(255,240,220,.9)',sz:rand(2,4),g:0});}
    else if(f.t==='rays'){continue;ctx.save();ctx.globalCompositeOperation='lighter';ctx.translate(f.x,f.y);ctx.globalAlpha=k;for(let i=0;i<12;i++){const an=f.a+i*Math.PI/6,L=60+180*(1-k);ctx.strokeStyle=i%2?'#ffe14a':'#fff';ctx.lineWidth=4*k+1;ctx.beginPath();ctx.moveTo(Math.cos(an)*18,Math.sin(an)*18);ctx.lineTo(Math.cos(an)*L,Math.sin(an)*L);ctx.stroke();}ctx.restore();}
    else if(f.t==='gcrack'){continue;ctx.save();ctx.globalAlpha=Math.min(1,k*2);ctx.strokeStyle='#1a0d10';ctx.lineWidth=4;for(const s of f.seg){ctx.beginPath();ctx.moveTo(f.x,GY+4);ctx.lineTo(f.x+s[0]*180*s[1],GY+4+s[1]*40);ctx.stroke();}
      ctx.globalCompositeOperation='lighter';ctx.strokeStyle='#ffb347';ctx.lineWidth=1.5;for(const s of f.seg){ctx.beginPath();ctx.moveTo(f.x,GY+4);ctx.lineTo(f.x+s[0]*180*s[1],GY+4+s[1]*40);ctx.stroke();}ctx.restore();}
  }
  ctx.globalAlpha=1;
  for(const p of projs){
    if(p.k==='wave'){ctx.save();ctx.globalCompositeOperation='lighter';ctx.translate(p.x,p.y);ctx.scale(Math.sign(p.vx),1);ctx.drawImage(IMG.fx_slashC,-120,-120,240,240);ctx.restore();}
    else if(p.k==='sword'){ctx.strokeStyle=p.col;ctx.globalAlpha=.4;ctx.lineWidth=8;ctx.beginPath();ctx.moveTo(p.x,p.y-90);ctx.lineTo(p.x,p.y);ctx.stroke();
      ctx.globalAlpha=1;ctx.strokeStyle='#fff';ctx.lineWidth=3;ctx.beginPath();ctx.moveTo(p.x,p.y-46);ctx.lineTo(p.x,p.y);ctx.stroke();ctx.strokeStyle='#ffd76a';ctx.lineWidth=4;ctx.beginPath();ctx.moveTo(p.x-9,p.y-46);ctx.lineTo(p.x+9,p.y-46);ctx.stroke();}
    else if(p.k==='naga'){const im=IMG.fx_naga,dw=480,dh=dw*im.naturalHeight/im.naturalWidth,N=24,sw=im.naturalWidth/N;ctx.save();ctx.globalCompositeOperation='lighter';ctx.translate(p.x,p.y);ctx.scale(Math.sign(p.vx),1);ctx.globalAlpha=Math.min(1,p.life*3);
      for(let i=0;i<N;i++){const k=i/N,dy=Math.sin(p.t*11-k*7)*16*(1-k*.6);ctx.drawImage(im,i*sw,0,sw+1,im.naturalHeight,-dw*.7+k*dw,-dh/2+dy,dw/N+1,dh);}ctx.restore();}
    else if(p.k==='chakra'){ctx.save();ctx.globalCompositeOperation='lighter';ctx.translate(p.x,p.y);ctx.rotate(p.t*32);ctx.drawImage(IMG.fx_chakra,-75,-75,150,150);ctx.restore();}
    else if(p.k==='clone'){const fk='h_atk',m=FM[fk][p.f+1],im=IMG[fk+(p.f+1)];ctx.save();ctx.translate(p.x,p.y);ctx.scale(p.face,1);ctx.globalAlpha=Math.min(.9,p.life*3);
      ctx.globalAlpha*=.6;ctx.drawImage(tint(im,'#2a1050'),-m.w*m.ax,-m.h,m.w,m.h);ctx.globalAlpha/=.6*1.4;ctx.drawImage(im,-m.w*m.ax,-m.h,m.w,m.h);ctx.globalCompositeOperation='lighter';ctx.globalAlpha=.35;ctx.drawImage(tint(im,'#7a4aff'),-m.w*m.ax-3,-m.h,m.w,m.h);ctx.restore();}
    else if(p.k==='b')drawBullet(p);
    else if(p.k==='giant'){ctx.save();ctx.globalCompositeOperation='lighter';ctx.globalAlpha=Math.min(1,p.life*2);if(ok(IMG[p.img||'fx_giant']))ctx.drawImage(IMG[p.img||'fx_giant'],p.x-230,p.y-230,460,460);ctx.restore();}
  }
  ctx.globalAlpha=1;
  for(const p of parts){ctx.globalAlpha=Math.min(1,p.life/p.max*1.5);ctx.fillStyle=p.col;
    if(p.solid){ctx.globalCompositeOperation='source-over';if(p.rot!==undefined){ctx.save();ctx.translate(p.x,p.y);ctx.rotate(p.rot);ctx.fillRect(-p.sz/2,-p.sz/3,p.sz,p.sz*.66);ctx.restore();}else ctx.fillRect(p.x-p.sz/2,p.y-p.sz/2,p.sz,p.sz);}
    else{ctx.globalCompositeOperation='lighter';ctx.fillRect(p.x-p.sz/2,p.y-p.sz/2,p.sz,p.sz);}}
  ctx.globalCompositeOperation='source-over';ctx.globalAlpha=1;ctx.textAlign='center';
  for(const t of texts){ctx.globalAlpha=Math.min(1,t.life/t.max*2);const age=t.max-t.life,ps=t.pop&&age<t.pop?1+(1-age/t.pop)*1.4:1;ctx.save();ctx.translate(t.x,t.y);ctx.scale(ps,ps);if(t.crit||t.lab)ctx.rotate(-.08);ctx.font=`${t.lab?'italic ':''}900 ${t.sz}px system-ui,sans-serif`;
    if(t.crit){ctx.lineWidth=9;ctx.strokeStyle='#5a0008';ctx.strokeText(t.txt,0,0);ctx.lineWidth=4;ctx.strokeStyle='#ff3040';ctx.strokeText(t.txt,0,0);const g=ctx.createLinearGradient(0,-t.sz,0,0);g.addColorStop(0,'#fffbe0');g.addColorStop(1,'#ffb02e');ctx.fillStyle=g;ctx.fillText(t.txt,0,0);}
    else{ctx.lineWidth=t.sz>30?6:4;ctx.strokeStyle=t.lab?'#2a0005':'#000';ctx.strokeText(t.txt,0,0);ctx.fillStyle=t.col;ctx.fillText(t.txt,0,0);}ctx.restore();}
  ctx.globalAlpha=1;
}
function txt(s,x,y,size,col,align='center',w=900){ctx.font=`${w} ${size}px system-ui,"Noto Sans Thai",sans-serif`;ctx.textAlign=align;ctx.lineWidth=Math.max(3,size/7);ctx.strokeStyle='rgba(0,0,0,.85)';ctx.strokeText(s,x,y);ctx.fillStyle=col;ctx.fillText(s,x,y);}
function drawHUD(){if(scene==='town'){drawTownHUD();return;}
  ctx.fillStyle='#000a';ctx.fillRect(16,16,224,14);ctx.fillStyle='#ff5b6e';ctx.fillRect(18,18,220*P.hp/P.maxHp,10);
  const full=energy>=100&&!run&&!finale;
  ctx.fillStyle='#000a';ctx.fillRect(16,52,224,14);ctx.fillStyle=full?`hsl(${t0*300%360},90%,65%)`:'#6a8cff';ctx.fillRect(18,54,220*energy/100,10);
  ctx.fillStyle='#000a';ctx.fillRect(16,70,224,8);ctx.fillStyle=P.core>=100?`hsl(${45+15*Math.sin(t0*10)},100%,65%)`:'#e0b84a';ctx.fillRect(18,72,220*P.core/100,4);txt('Core'+(P.core>=100?' พร้อม! ('+(isTouch?'◆':'F')+')':''),246,79,11,P.core>=100?'#ffe066':'#cdb98a','left',700);
  txt('HP '+Math.max(0,Math.ceil(P.hp))+'/'+P.maxHp,236,28,11,'#fff','right',800);txt('พลังโจมตี ×'+atkMul().toFixed(2),18,112,13,'#ffcf9a','left',700);{const gs=1+goldT*.5;if(ok(IMG.ui_coin))ctx.drawImage(IMG.ui_coin,16,122,22,22);ctx.save();ctx.translate(42,139);ctx.scale(gs,gs);txt(gold.toLocaleString(),0,0,15,'#ffd76a','left',800);ctx.restore();if(ok(IMG.ui_stone))ctx.drawImage(IMG.ui_stone,120,122,22,22);txt(''+stones,146,139,15,'#d8c2ff','left',800);txt(MD().n,190,139,12,MD().col,'left',800);}
  pickups.forEach((p,i)=>{if(p.stone){const a=Math.min(1,p.life/p.max*3),y=H-210-i*40;ctx.globalAlpha=a;ctx.fillStyle='rgba(15,10,25,.8)';ctx.fillRect(W-330,y-24,312,36);ctx.fillStyle='#b98cff';ctx.fillRect(W-330,y-24,4,36);if(ok(IMG.ui_stone))ctx.drawImage(IMG.ui_stone,W-322,y-21,30,30);txt('หินตีบวก +1 (มี '+stones+')',W-286,y+2,15,'#d8c2ff','left',800);ctx.globalAlpha=1;return;}const R=RAR[p.it.r],a=Math.min(1,p.life/p.max*3),y=H-210-i*40;ctx.globalAlpha=a;ctx.fillStyle='rgba(15,10,25,.8)';ctx.fillRect(W-330,y-24,312,36);ctx.fillStyle=R.c;ctx.fillRect(W-330,y-24,4,36);
    const im=IMG[iicon(p.it)];if(ok(im))ctx.drawImage(im,W-322,y-21,30,30);txt(iname(p.it)+' ('+R.n+')',W-286,y-6,14,R.c,'left',800);txt(istatTxt(p.it).slice(0,46)+' · '+p.msg,W-286,y+9,11,'#ddd','left',600);ctx.globalAlpha=1;});txt('พลัง',246,65,12,'#cfd8ff','left',700);if(full)txt((isTouch?'★':'X')+' ปล่อยคอมโบ '+chainTime().toFixed(1)+' วิ!',18,92,16,'#ffd76a','left');
  if(tut){drawTut();}else{txt('ด่าน '+stage,W-18,32,18,'#fff','right');
  txt('กำจัด '+Math.min(kills,quota)+' / '+quota,W-18,56,15,kills>=quota?'#ffd76a':'#cfc6e8','right',700);
  if(!isTouch&&!run&&!finale)txt('C จัดคอมโบ',W-18,78,12,'#8d83aa','right',600);}
  if(!tut&&!run&&!finale&&!bigTotal){const mw=300,mx=(W-mw)/2,my=24;ctx.fillStyle='rgba(10,6,20,.6)';ctx.fillRect(mx-6,my-8,mw+12,16);ctx.fillStyle='#4a3d66';ctx.fillRect(mx,my-1,mw,2);
    for(const e of enemies){if(e.dead)continue;ctx.fillStyle=ET[e.type].mm;ctx.fillRect(mx+e.x/WORLD_W*mw-1,my-3,2,6);}
    ctx.fillStyle=kills>=quota?'#ffd76a':'#888';ctx.beginPath();ctx.arc(mx+portalX/WORLD_W*mw,my,5,0,7);ctx.fill();
    ctx.fillStyle='#fff';ctx.beginPath();ctx.arc(mx+P.x/WORLD_W*mw,my,4,0,7);ctx.fill();
    if(kills>=quota)txt('ไปที่ประตูวาร์ป →',W/2,54,15,'#ffd76a');drawBossBar();}
  drawSkillCluster();drawHitCounter();
  if(run){const bw=420,bx=(W-bw)/2,by=20;ctx.fillStyle='#000b';ctx.fillRect(bx-4,by-4,bw+8,22);let x=bx;
    chain.forEach((id,i)=>{const w=bw*SK[id].dur/run.dur;ctx.fillStyle=i<run.i?'#555':i===run.i?SK[id].col:'#2a2240';ctx.globalAlpha=i===run.i?1:.85;ctx.fillRect(x+1,by,w-2,14);x+=w;});
    ctx.globalAlpha=1;const px=bx+bw*Math.min(1,run.total/run.dur);ctx.fillStyle='#fff';ctx.fillRect(px-1.5,by-4,3,22);
    const id=chain[run.i];const pk=1+Math.max(0,.25-run.t)*1.6;ctx.save();ctx.translate(W/2,74);ctx.scale(pk,pk);drawIcon(id,-30,-30,60,60);ctx.restore();
    txt(SK[id].name+(run.syn?'  ×'+run.mult:''),W/2,132,24,run.syn?'#ffd76a':SK[id].col);
    txt((run.dur-run.total).toFixed(1)+' วิ',W/2,152,14,'#cfc6e8','center',700);
    const s=1+.12*Math.sin(t0*30);ctx.save();ctx.translate(W-30,140);ctx.scale(s,s);txt(run.hits+' HIT',0,0,40,'#ffd76a','right');ctx.restore();
    txt(run.dmg.toLocaleString()+' DMG',W-30,168,16,'#fff','right',700);}
  if(!isTouch&&!run&&!finale&&!bigTotal){const ks=[['A D','เดิน'],['S','กระโดด'],['Z','ฟัน'],['Shift','หลบ'],['F','Core'],['X','คอมโบ'],['C','จัดคอมโบ']];let x=16;ctx.font='700 13px system-ui,sans-serif';
    for(const [k,l] of ks){const kw=ctx.measureText(k).width+14;ctx.fillStyle='rgba(20,14,30,.75)';ctx.fillRect(x,H-34,kw,22);ctx.strokeStyle='rgba(255,255,255,.4)';ctx.strokeRect(x+.5,H-33.5,kw-1,21);ctx.fillStyle='#fff';ctx.textAlign='left';ctx.fillText(k,x+7,H-18);x+=kw+4;txt(l,x,H-18,12,'#e8e0ff','left',600);x+=ctx.measureText(l).width+14;}}
  if(finale&&finale.phase===0){const k=Math.min(1,finale.t/1.1);ctx.save();ctx.translate(W/2,H/2-150);const s=.8+k*.5;ctx.scale(s,s);ctx.globalAlpha=k;
    ctx.shadowColor='#ff2030';ctx.shadowBlur=30;txt('ปิดฉาก',0,0,64,'#ffe0e0');ctx.restore();}
  if(bigTotal){const k=bigTotal.life/bigTotal.max,a=Math.min(1,k*3),age=bigTotal.max-bigTotal.life;ctx.globalAlpha=a;
    const pop=age<.18?2.6-age/.18*1.6:1;const jx=age<.3?rand(-6,6):0;
    ctx.save();ctx.translate(W/2-70+jx,H/2-40);ctx.scale(pop,pop);ctx.shadowColor='#ff8a00';ctx.shadowBlur=24;txt(bigTotal.hits.toLocaleString()+' HIT',0,0,78,'#ffd76a');ctx.restore();
    if(age>.15)txt(bigTotal.dmg.toLocaleString()+' DMG',W/2-70,H/2+20,34,'#fff');
    if(age>.35){const rp=age<.5?2-(age-.35)/.15:1;ctx.save();ctx.translate(W/2+250,H/2-30);ctx.rotate(-.18);ctx.scale(rp,rp);
      const gr=ctx.createLinearGradient(0,-60,0,30);gr.addColorStop(0,'#fff6c8');gr.addColorStop(.5,'#ffc93c');gr.addColorStop(1,'#ff6a00');
      ctx.shadowColor='#ff3000';ctx.shadowBlur=30;ctx.font='italic 900 110px system-ui,sans-serif';ctx.textAlign='center';ctx.lineWidth=12;ctx.strokeStyle='#2a0800';ctx.strokeText(bigTotal.rank,0,0);ctx.fillStyle=gr;ctx.fillText(bigTotal.rank,0,0);ctx.restore();
      txt(bigTotal.rank.startsWith('S')?'สุดโหด!!':'เยี่ยม!',W/2+250,H/2+40,24,'#ffb3b3');}
    ctx.globalAlpha=1;}
  if(banner){ctx.globalAlpha=Math.min(1,banner.life/banner.max*3);txt(banner.t,W/2,190,30,banner.col);ctx.globalAlpha=1;}
  if(toast){ctx.globalAlpha=Math.min(1,toast.life/toast.max*3);txt(toast.t,W/2,H-60,18,toast.col,'center',700);ctx.globalAlpha=1;}
}
function drawTownHUD(){
  if(ok(IMG.ui_coin))ctx.drawImage(IMG.ui_coin,16,14,26,26);txt(gold.toLocaleString(),48,34,18,'#ffd76a','left',800);if(ok(IMG.ui_stone))ctx.drawImage(IMG.ui_stone,150,14,26,26);txt(''+stones,182,34,18,'#d8c2ff','left',800);
  txt('🏯 เมือง · '+CLS[cls].n+' · โหมด '+MD().n,W-18,32,17,'#fff','right',800);txt('ด่านถัดไป: '+stage,W-18,54,14,'#ffd76a','right',700);
  const mw=300,mx=(W-mw)/2,my=24;ctx.fillStyle='rgba(10,6,20,.6)';ctx.fillRect(mx-6,my-8,mw+12,16);ctx.fillStyle='#4a3d66';ctx.fillRect(mx,my-1,mw,2);
  for(const n of NPCS){ctx.fillStyle=n.col;ctx.beginPath();ctx.arc(mx+n.x/WORLD_W*mw,my,4,0,7);ctx.fill();}ctx.fillStyle='#ffd76a';ctx.fillRect(mx+portalX/WORLD_W*mw-3,my-6,6,12);ctx.fillStyle='#fff';ctx.beginPath();ctx.arc(mx+P.x/WORLD_W*mw,my,4,0,7);ctx.fill();
  if(!isTouch){const ks=[['A D','เดิน'],['W / Enter','คุยกับ NPC'],['C','เมนู'],['→','ประตูออกเดินทาง']];let x=16;ctx.font='700 13px system-ui,sans-serif';
    for(const [k,l] of ks){const kw=ctx.measureText(k).width+14;ctx.fillStyle='rgba(20,14,30,.75)';ctx.fillRect(x,H-34,kw,22);ctx.strokeStyle='rgba(255,255,255,.4)';ctx.strokeRect(x+.5,H-33.5,kw-1,21);ctx.fillStyle='#fff';ctx.textAlign='left';ctx.fillText(k,x+7,H-18);x+=kw+4;txt(l,x,H-18,12,'#e8e0ff','left',600);x+=ctx.measureText(l).width+14;}}
  if(banner){ctx.globalAlpha=Math.min(1,banner.life/banner.max*3);txt(banner.t,W/2,110,22,banner.col);ctx.globalAlpha=1;}
  if(toast){ctx.globalAlpha=Math.min(1,toast.life/toast.max*3);txt(toast.t,W/2,H-60,18,toast.col,'center',700);ctx.globalAlpha=1;}
  pickups.length=0;}
const fxC=document.createElement('canvas'),fxG=fxC.getContext('2d');
function postChroma(){const w=cv.width,h=cv.height;if(fxC.width!==w){fxC.width=w;fxC.height=h;}const d=Math.round(chroma*14*dpr);
  ctx.save();ctx.setTransform(1,0,0,1,0,0);
  for(const [c,o] of [['#ff0000',d],['#00ffff',-d]]){fxG.globalCompositeOperation='source-over';fxG.drawImage(cv,0,0);fxG.globalCompositeOperation='multiply';fxG.fillStyle=c;fxG.fillRect(0,0,w,h);
    ctx.globalCompositeOperation='lighter';ctx.globalAlpha=.35*chroma;ctx.drawImage(fxC,o,0);}
  ctx.restore();}
function speedLines(a){ctx.save();ctx.globalAlpha=a;ctx.strokeStyle='#fff';ctx.lineWidth=2;const cx=W/2,cy=H/2;for(let i=0;i<46;i++){const ang=rand(0,6.3),r0=rand(260,380),r1=r0+rand(160,320);
  ctx.beginPath();ctx.moveTo(cx+Math.cos(ang)*r0,cy+Math.sin(ang)*r0*.75);ctx.lineTo(cx+Math.cos(ang)*r1,cy+Math.sin(ang)*r1*.75);ctx.stroke();}ctx.restore();}
// ===== บรรยากาศ: ละอองลอยในฉาก (มีความลึกแบบ parallax) + แสง =====
const MOTE={bg:['255,150,70',-1],bg_forest:['190,255,140',0],bg_ruins:['235,215,180',1],bg_sky:['255,225,140',-1],town:['255,190,110',-1]};
function moteKind(){return scene==='town'?'town':stageBg()[0];}
function updateMotes(dt){const mk=MOTE[moteKind()]||MOTE.bg;
  while(motes.length<46){const z=Math.random()<.18?rand(1.15,1.5):rand(.35,1);motes.push({x:rand(0,W+80),y:rand(40,GY),z,vy:mk[1]*rand(8,26)*z-(mk[1]===0?0:4),ph:rand(0,6.3),sz:rand(1.2,2.8)*z});}
  for(const m of motes){m.ph+=dt*(1+m.z);m.y+=m.vy*dt+Math.sin(m.ph)*6*dt;m.x+=Math.cos(m.ph*.7)*10*dt;if(m.y<20)m.y=GY;if(m.y>GY+10)m.y=40;}}
const GLOW={};function glow(rgb){if(GLOW[rgb])return GLOW[rgb];const c=document.createElement('canvas');c.width=c.height=64;const g=c.getContext('2d'),gr=g.createRadialGradient(32,32,0,32,32,32);gr.addColorStop(0,`rgba(${rgb},1)`);gr.addColorStop(.4,`rgba(${rgb},.45)`);gr.addColorStop(1,`rgba(${rgb},0)`);g.fillStyle=gr;g.fillRect(0,0,64,64);return GLOW[rgb]=c;}
function drawMotes(front){const mk=MOTE[moteKind()]||MOTE.bg;ctx.save();ctx.globalCompositeOperation='lighter';
  for(const m of motes){if((m.z>1)!==front)continue;const sx=((m.x-camX*m.z*.6)%(W+80)+(W+80))%(W+80)-40,a=(.35+.35*Math.sin(m.ph*2))*(front?.5:1);
    const r=m.sz*(front?5:3);ctx.globalAlpha=Math.max(0,a);ctx.drawImage(glow(mk[0]),sx-r,m.y-r,r*2,r*2);}
  ctx.restore();}
function drawLights(){if(!lights.length)return;ctx.save();ctx.globalCompositeOperation='lighter';
  for(const l of lights){const k=l.life/l.max,r=l.r*(1.15-.15*k);ctx.globalAlpha=Math.min(1,l.a*k);ctx.drawImage(glow(l.rgb),l.x-r,l.y-r,r*2,r*2);}
  ctx.restore();}
function drawEE(){if(eeT<=0)return;const k=Math.min(1,eeT/.25,(eeMax-eeT)/.12+.2);
  ctx.save();ctx.globalCompositeOperation='multiply';ctx.fillStyle=`rgba(120,150,255,${.55*k})`;ctx.fillRect(0,0,W,H);ctx.restore();
  const vg=ctx.createRadialGradient(W/2,H/2,H*.3,W/2,H/2,H*.85);vg.addColorStop(0,'rgba(0,10,40,0)');vg.addColorStop(1,`rgba(10,20,70,${.6*k})`);ctx.fillStyle=vg;ctx.fillRect(0,0,W,H);
  ctx.globalAlpha=k;{const ps=1+Math.max(0,.2-(eeMax-eeT))*4;ctx.save();ctx.translate(W/2,168);ctx.scale(ps,ps);ctx.shadowColor='#3a7bff';ctx.shadowBlur=20;txt('EXTREME EVASION',0,0,30,'#cfeeff','center',900);ctx.restore();}
  if(!P.cnt){const pk=1+.08*Math.sin(t0*18),cx=W/2,cy=232;ctx.save();ctx.translate(cx,cy);ctx.scale(pk,pk);
    ctx.lineWidth=5;ctx.strokeStyle='rgba(255,255,255,.25)';ctx.beginPath();ctx.arc(0,0,34,0,7);ctx.stroke();ctx.strokeStyle='#c9a8ff';ctx.beginPath();ctx.arc(0,0,34,-Math.PI/2,-Math.PI/2+Math.PI*2*eeT/eeMax);ctx.stroke();
    ctx.fillStyle='rgba(30,15,60,.8)';ctx.beginPath();ctx.arc(0,0,29,0,7);ctx.fill();txt(isTouch?'⚔':'Z',0,9,isTouch?24:28,'#fff','center',900);ctx.restore();
    txt('สวนกลับ! (เงาวาร์ป)',cx,cy+58,17,'#e6d8ff','center',800);}
  ctx.globalAlpha=1;}
function ring2(x,y,r,p,col,w){ctx.lineWidth=w;ctx.strokeStyle='rgba(0,0,0,.55)';ctx.beginPath();ctx.arc(x,y,r,0,7);ctx.stroke();if(p>0){ctx.strokeStyle=col;ctx.beginPath();ctx.arc(x,y,r,-Math.PI/2,-Math.PI/2+Math.PI*2*Math.min(1,p));ctx.stroke();}}
// ปุ่มสกิลมุมขวาล่าง แบบเกมแอ็กชัน: วงรอบปุ่มบอกคูลดาวน์/เกจ
function skillBtn(x,y,r,icon,key,p,col,ready,dim){ctx.save();
  if(ready){ctx.globalCompositeOperation='lighter';const g=ctx.createRadialGradient(x,y,r*.6,x,y,r*1.9);g.addColorStop(0,col);g.addColorStop(1,'rgba(0,0,0,0)');ctx.globalAlpha=.35+.2*Math.sin(t0*8);ctx.fillStyle=g;ctx.fillRect(x-r*2,y-r*2,r*4,r*4);ctx.globalCompositeOperation='source-over';ctx.globalAlpha=1;}
  ctx.fillStyle='rgba(12,8,24,.78)';ctx.beginPath();ctx.arc(x,y,r,0,7);ctx.fill();
  const im=IMG[icon];if(ok(im)){ctx.save();ctx.beginPath();ctx.arc(x,y,r-5,0,7);ctx.clip();ctx.globalAlpha=dim?.35:1;ctx.drawImage(im,x-r+5,y-r+5,(r-5)*2,(r-5)*2);ctx.restore();}
  if(dim&&p<1){ctx.fillStyle='rgba(0,0,0,.45)';ctx.beginPath();ctx.moveTo(x,y);ctx.arc(x,y,r-4,-Math.PI/2+Math.PI*2*p,Math.PI*1.5);ctx.fill();}
  ring2(x,y,r,p,ready?`hsl(${t0*300%360},90%,70%)`:col,4);
  ctx.fillStyle='rgba(0,0,0,.8)';ctx.font='800 11px system-ui,sans-serif';const kw=ctx.measureText(key).width+10;ctx.fillRect(x-kw/2,y+r-6,kw,15);ctx.fillStyle='#fff';ctx.textAlign='center';ctx.fillText(key,x,y+r+5);
  ctx.restore();}
const ATK_IC={sword:'ic_slash',shaman:'ic_m_orb',archer:'ic_a_rapid'},CORE_IC={sword:'ic_xslash',shaman:'ic_m_ritual',archer:'ic_a_pierce'};
function drawSkillCluster(){if(isTouch||run||finale||bigTotal)return;
  skillBtn(W-62,H-66,36,ATK_IC[cls],'Z',1,'#e8e0ff',false,false);
  skillBtn(W-150,H-44,25,'ic_dash','Shift',1-P.dodgeCD/.5,'#9fd8ff',false,P.dodgeCD>0);
  skillBtn(W-140,H-122,29,CORE_IC[cls],'F',P.core/100,'#ffe066',P.core>=100,P.core<100);
  skillBtn(W-58,H-158,31,chain.length?icId(chain[0]):ATK_IC[cls],'X',energy/100,'#8fb0ff',energy>=100,energy<100);}
function bossTarget(){let b=null,bd=1e9;for(const e of enemies){if(e.dead||e.doomed||!e.brkMax||!e.aggro)continue;if(e.x<camX-40||e.x>camX+W+40)continue;const d=Math.abs(e.x-P.x)+(e.type==='golem'?-2000:0);if(d<bd){bd=d;b=e;}}return b;}
function drawBossBar(){const e=bossTarget();if(!e)return;const bw=340,bx=W/2-170,by=104;
  txt(ET[e.type].name+'  Lv.'+stage,bx,by-6,14,'#f1e6ff','left',800);txt(Math.max(0,Math.ceil(e.hp)).toLocaleString()+' / '+e.max.toLocaleString(),bx+bw,by-6,12,'#ddd','right',700);
  ctx.fillStyle='rgba(0,0,0,.7)';ctx.fillRect(bx-2,by-2,bw+4,14);ctx.fillStyle='#fff';ctx.fillRect(bx,by,bw*Math.max(0,Math.min(1,e.hpLag/e.max)),10);
  const g=ctx.createLinearGradient(0,by,0,by+10);g.addColorStop(0,'#ff6a7a');g.addColorStop(1,'#b0162a');ctx.fillStyle=g;ctx.fillRect(bx,by,bw*Math.max(0,e.hp/e.max),10);
  const k=e.broken>0?e.broken/3.5:Math.min(1,e.brkV/e.brkMax);ctx.fillStyle='rgba(0,0,0,.7)';ctx.fillRect(bx-2,by+14,bw+4,8);
  ctx.fillStyle=e.broken>0?(Math.floor(t0*10)%2?'#ffffff':'#7ff3ff'):'#4fc8ff';ctx.fillRect(bx,by+16,bw*k,4);
  txt(e.broken>0?'BREAK!':'BREAK',bx+bw+8,by+22,11,e.broken>0?'#7ff3ff':'#8ab4cc','left',800);}
function drawHitCounter(){if(run||finale||P.hc<3||P.hcT<=0)return;const a=Math.min(1,P.hcT/.4),s=1+Math.max(0,P.hcT-2)*1.5;
  ctx.save();ctx.globalAlpha=a;ctx.translate(W-30,250);ctx.scale(s,s);ctx.rotate(-.05);ctx.font='italic 900 46px system-ui,sans-serif';ctx.textAlign='right';ctx.lineWidth=7;ctx.strokeStyle='#1a0820';ctx.strokeText(P.hc,0,0);
  const g=ctx.createLinearGradient(0,-40,0,0);g.addColorStop(0,'#fff');g.addColorStop(1,P.hc>=50?'#ff5b9a':P.hc>=20?'#ffd76a':'#9fd8ff');ctx.fillStyle=g;ctx.fillText(P.hc,0,0);
  ctx.font='italic 800 15px system-ui,sans-serif';ctx.lineWidth=4;ctx.strokeText('HITS',0,20);ctx.fillStyle='#e8e0ff';ctx.fillText('HITS',0,20);ctx.restore();
  ctx.fillStyle='rgba(255,255,255,.6)';ctx.fillRect(W-30-90*Math.min(1,P.hcT/2.2),262,90*Math.min(1,P.hcT/2.2),3);}

function render(){
  ctx.setTransform(dpr,0,0,dpr,0,0);
  const sx=(Math.random()-.5)*shake,sy=(Math.random()-.5)*shake;
  const psx=P.x-camX;const k=Math.max(0,Math.min(1,(zoom-1)/.4));const fx=W/2+(psx-W/2)*k,fy=H/2+(P.y-90-H/2)*k;
  const zz=zoom*(1+punch*1.2);ctx.save();ctx.translate(W/2+sx,H/2+sy);ctx.scale(zz,zz);ctx.translate(-fx,-fy);
  drawBG();drawMotes(false);
  ctx.translate(-camX,0);
  if(!tut)drawPortal();if(scene==='town')drawNpcs();
  for(const e of enemies)if(e.x>camX-200&&e.x<camX+W+200)drawEnemy(e);
  drawDrops();drawVortex();drawRunExtras();drawPlayer();drawFx();drawLights();
  ctx.restore();drawMotes(true);drawEE();
  if(desat>.01){ctx.globalCompositeOperation='saturation';ctx.fillStyle=`rgba(128,128,128,${desat})`;ctx.fillRect(0,0,W,H);ctx.globalCompositeOperation='source-over';}
  if(dark>.01||desat>.01){const vg=ctx.createRadialGradient(W/2,H/2,H*.22,W/2,H/2,H*.8);vg.addColorStop(0,`rgba(40,0,0,${dark*.2})`);vg.addColorStop(1,`rgba(0,0,0,${Math.min(.92,desat*.6+dark)})`);ctx.fillStyle=vg;ctx.fillRect(0,0,W,H);}

  if(blackT>0&&finale&&finale.phase===1){ctx.fillStyle='#000';ctx.fillRect(0,0,W,H);ctx.save();ctx.translate(W/2,H/2);ctx.scale(zoom,zoom);ctx.translate(-fx,-fy);ctx.translate(-camX,0);
    for(const e of enemies)if(!e.dead&&(e.marked||e.doomed))drawEnemy(e,true);drawPlayer(true);ctx.restore();}

  if(cracks){const a=Math.min(1,cracks.life/cracks.max*2);ctx.save();ctx.lineJoin='round';ctx.globalAlpha=a;
    for(const pass of [[5,'rgba(0,0,0,.55)'],[1.6,'rgba(255,255,255,.95)']]){ctx.lineWidth=pass[0];ctx.strokeStyle=pass[1];for(const c of cracks.pts){ctx.beginPath();c.forEach((p,i)=>i?ctx.lineTo(p[0],p[1]):ctx.moveTo(p[0],p[1]));ctx.stroke();}}ctx.restore();}
  if(critFl>0){const vg=ctx.createRadialGradient(W/2,H/2,H*.35,W/2,H/2,H*.85);vg.addColorStop(0,'rgba(255,0,30,0)');vg.addColorStop(1,`rgba(255,20,50,${critFl*.55})`);ctx.fillStyle=vg;ctx.fillRect(0,0,W,H);}
  if(flash>0){ctx.fillStyle=`rgba(255,255,255,${Math.min(1,flash)})`;ctx.fillRect(0,0,W,H);}
  drawHUD();
}
let last=performance.now();
function loop(now){const rdt=Math.min(.05,(now-last)/1000);last=now;update(rdt);render();touchGauges();requestAnimationFrame(loop);}

// ================= ลำดับเกม =================
function startStage(){scene='stage';projs=[];fxs=[];parts=[];texts=[];trail=[];run=null;finale=null;bigTotal=null;cracks=null;doomedN=0;timeScale=1;zoomT=1;desatT=0;darkT=0;blackT=0;
  WORLD_W=Math.min(8000,3600+600*stage);portalX=WORLD_W-160;
  P.x=150;P.y=GY;P.vx=P.vy=0;P.face=1;P.maxHp=maxHpOf();P.hp=P.maxHp;P.inv=1;P.ihit=1;P.finisher=0;P.cnt=null;P.coreA=0;P.dodgeT=0;P.core=0;P.hc=0;eeT=0;eeSrc=null;lights=[];kills=0;quota=16+6*stage;energy=20;spawnT=.6;camX=0;
  populate();state='play';banner={t:'ด่าน '+stage+' · '+stageBg()[1]+' — ไปทางขวา →',col:'#fff',life:1.8,max:1.8};hideMsg();}
function stageClear(){const oldN=unlockedN(),oldCap=capOf();stage++;save.stage=stage;save.shop=null;saveEq();persist();
  let t='✨ ผ่านด่าน '+(stage-1)+'!';const nN=unlockedN();if(nN>oldN)t+=' · ปลดล็อกสกิล: '+ORDER.slice(oldN,nN).map(i=>SK[i].name).join(', ');
  if(capOf()>oldCap)t+=' · คอมโบยาวสุด '+capOf()+' วิ';sTone(523,1046,.4,.15,'triangle');openHub(t);}
const msgEl=document.getElementById('msg');
function showMsg(title,html,goLabel,onGo){document.getElementById('mTitle').textContent=title;document.getElementById('mText').innerHTML=html;
  const g=document.getElementById('mGo');g.textContent=goLabel;g.onclick=onGo;const me=document.getElementById('mEdit');me.onclick=()=>{hideMsg();openEditor('start');};msgEl.classList.add('show');}
function hideMsg(){msgEl.classList.remove('show');}
const edEl=document.getElementById('editor');
let curTab='skill',enhSel=null;
// ===== เมือง (แมพเดินได้ มี NPC) =====
const NPCS=[{x:430,img:'npc_s',name:'ช่างตีเหล็ก',role:'ตีบวกอุปกรณ์',tab:'enh',col:'#ff9a3d'},{x:900,img:'npc_m',name:'ลุงพ่อค้า',role:'ซื้อ-ขายของ',tab:'shop',col:'#ffd76a'},{x:1370,img:'npc_r',name:'ฤๅษีสอนวิชา',role:'จัดคอมโบสกิล',tab:'skill',col:'#9fe8ff'}];
let nearNpc=null,activeNpc=null;
const canUseService=tab=>scene==='town'&&state==='edit'&&activeNpc?.tab===tab;
function canOpenTab(tab){
  if(!activeNpc)return tab!=='shop'&&tab!=='enh';
  return canUseService(tab)||(tab==='equip'&&canUseService('shop'));
}
function enterTown(note){nearNpc=activeNpc=null;scene='town';edEl.classList.remove('show');hideMsg();projs=[];fxs=[];parts=[];texts=[];trail=[];enemies=[];drops=[];run=null;finale=null;bigTotal=null;cracks=null;doomedN=0;timeScale=1;zoomT=1;desatT=0;darkT=0;blackT=0;
  WORLD_W=1960;portalX=WORLD_W-130;P.x=150;P.y=GY;P.vx=P.vy=0;P.face=1;P.maxHp=maxHpOf();P.hp=P.maxHp;P.inv=0;P.finisher=0;P.cnt=null;P.coreA=0;P.dodgeT=0;eeT=0;lights=[];camX=0;energy=0;state='play';
  banner={t:note||('🏯 เมือง — '+CLS[cls].n),col:'#ffd76a',life:3,max:3};}
function openHub(note){enterTown(note);}
function talk(){if(scene!=='town'||state!=='play'||!nearNpc||Math.abs(P.x-nearNpc.x)>=90)return;sUI();activeNpc=nearNpc;curTab=nearNpc.tab;afterEdit='town';document.getElementById('hubNote').textContent=nearNpc.name+': '+({enh:'จะตีอะไรดีล่ะ? ยิ่งสูงยิ่งเสี่ยงนะ!',shop:'ของใหม่มาทุกด่านเลยหลาน!',skill:'มาฝึกเรียงกระบวนท่ากันเถิด'})[nearNpc.tab];openPanel();}
function drawNpcs(){nearNpc=null;for(const n of NPCS){const d=Math.abs(P.x-n.x);if(d<90)nearNpc=n;const im=IMG[n.img];if(!ok(im))continue;const h=150,w=h*im.naturalWidth/im.naturalHeight,b=Math.sin(t0*2+n.x)*2;
    ctx.fillStyle='rgba(0,0,0,.35)';ctx.beginPath();ctx.ellipse(n.x,GY+2,w*.35,7,0,0,7);ctx.fill();
    ctx.save();ctx.translate(n.x,GY);ctx.scale(P.x<n.x?1:-1,1+.012*Math.sin(t0*3+n.x));ctx.drawImage(im,-w/2,-h+b,w,h);ctx.restore();
    txt(n.name,n.x,GY-h-22,15,n.col,'center',800);txt(n.role,n.x,GY-h-6,11,'#e8e0ff','center',600);
    if(nearNpc===n){const y=GY-h-56+Math.sin(t0*6)*3;ctx.fillStyle='rgba(15,10,25,.85)';ctx.fillRect(n.x-92,y-18,184,26);ctx.strokeStyle=n.col;ctx.strokeRect(n.x-92+.5,y-17.5,183,25);txt((isTouch?'แตะ ☰':'กด W / Enter')+' คุย',n.x,y,13,'#fff','center',800);}}}
function openEditor(after){activeNpc=null;afterEdit=after;document.getElementById('hubNote').textContent=after==='resume'?'⏸ หยุดเกมชั่วคราว — ร้านค้ากับตีบวกใช้ได้เฉพาะในเมือง (หลังเข้าประตูวาร์ป)':'';curTab='skill';openPanel();}
function openPanel(){state='edit';for(const k in keys)keys[k]=false;hideMsg();renderEditor();edEl.classList.add('show');}
function closeEditor(){activeNpc=null;edEl.classList.remove('show');save.chain=chain;saveEq();if(afterEdit==='resume'||afterEdit==='town')state='play';else startStage();}
function setTab(t){if(!canOpenTab(t))return;curTab=t;renderEditor();}
document.querySelectorAll('.tabs button').forEach(b=>b.onclick=()=>setTab(b.dataset.t));
const sellP=it=>Math.round(20*it.lv*Math.pow(RAR[it.r].m,2)*(1+(it.plus||0)*.35));
function itemCard(it,label,extra,attr,cls){if(!it)return`<div class="eqc empty"><small>${label}</small><b>ว่าง</b></div>`;const R=RAR[it.r];
  return`<div class="eqc ${cls||''}" ${attr||''} style="border-color:${R.c}${attr?';cursor:pointer':''}"><img src="assets/${iicon(it)}.webp"><div style="flex:1"><small>${label||SLOTN[it.slot]} · Lv.${it.lv} · ${R.n}</small><b style="color:${R.c}">${iname(it)}</b><span>${istat(it)}</span></div>${extra||''}</div>`;}
function renderEquip(){const el=document.getElementById('equip');
  const canSell=canUseService('shop');
  el.innerHTML=`<div class="eqrow">${SLOTS.map(k=>itemCard(eq[k],SLOTN[k])).join('')}</div>
    <div class="stat">โจมตี ×${atkMul().toFixed(2)} · HP ${maxHpOf()} · ลดดาเมจ ${Math.round(defOf()*100)}% · คริ ${Math.round(critOf()*100)}% (×${cdmgOf().toFixed(2)}) · เกจ +${Math.round((enMul()-1)*100)}% · เงิน +${Math.round((goldMul()-1)*100)}% · ความเร็ว +${Math.round((spdMul()-1)*100)}% · ดูดเลือด ${Math.round(lsOf()*100)}% · เวลาคอมโบ +${tot('ct')} วิ</div>
    <h3>กระเป๋า (${bag.length}/24) <small style="color:#8d83aa">ขอบสีบอกระดับ: ธรรมดา · <span style="color:#7fdc4a">ดี</span> · <span style="color:#5fb8ff">หายาก</span> · <span style="color:#c77dff">มหากาพย์</span> · <span style="color:#ffb02e">ตำนาน</span></small></h3><div class="bag">${bag.map((it,i)=>itemCard(it,null,`<button data-eq="${i}">ใส่</button>${canSell?`<button data-sell="${i}">ขาย ${sellP(it)}G</button>`:''}`)).join('')||'<span style="color:#6f6690;font-size:13px">ยังว่าง — ฟันมอนสเตอร์ให้ดรอปของ หรือซื้อที่ร้าน</span>'}</div>`;
  el.querySelectorAll('[data-eq]').forEach(b=>b.onclick=()=>{equipFromBag(+b.dataset.eq);renderEditor();});
  el.querySelectorAll('[data-sell]').forEach(b=>b.onclick=()=>{if(!canUseService('shop'))return;const i=+b.dataset.sell;if(!bag[i])return;gold+=sellP(bag[i]);bag.splice(i,1);saveEq();sTone(1200,1800,.1,.1,'triangle');renderEditor();});}
function shopStock(){if(save.shop&&save.shop.stage===stage)return save.shop;
  const items=[];for(let i=0;i<8;i++)items.push(makeItem(i===0?'weapon':SLOTS[Math.floor(Math.random()*SLOTS.length)],Math.min(4,rollR(12)),stage));
  save.shop={stage,items,stoneLeft:3};persist();return save.shop;}
const buyP=it=>Math.round(80*it.lv*Math.pow(RAR[it.r].m,2.2)*(1+it.subs.length*.25)*MD().price);
const stoneP=()=>Math.round(260*(1+.25*(stage-1))*MD().price);
function renderShop(){const el=document.getElementById('shop');if(!canUseService('shop')){el.innerHTML='';return;}
  const sh=shopStock();
  el.innerHTML=`<div class="npc"><img src="assets/npc_merchant.webp"><div><b>ลุงพ่อค้า:</b> ของใหม่มาทุกด่านเลยหลาน! ด่านยิ่งลึก ของยิ่งแรง ขายของเก่าได้ที่แท็บอุปกรณ์นะ</div></div>
    <div class="shop">${sh.items.map((it,i)=>it.sold?'':itemCard(it,null,`<div class="buy"><span class="price">${buyP(it).toLocaleString()} G</span><button data-buy="${i}" ${gold<buyP(it)?'disabled style="opacity:.4"':''}>ซื้อ</button></div>`)).join('')}
    <div class="eqc" style="border-color:#b98cff"><img src="assets/ui_stone.webp"><div style="flex:1"><small>วัตถุดิบ · เหลือ ${sh.stoneLeft} ชิ้น</small><b style="color:#d8c2ff">หินตีบวก</b><span>ใช้ตีบวกอุปกรณ์</span></div><div class="buy"><span class="price">${stoneP().toLocaleString()} G</span><button data-stone ${gold<stoneP()||!sh.stoneLeft?'disabled style="opacity:.4"':''}>ซื้อ</button></div></div></div>`;
  el.querySelectorAll('[data-buy]').forEach(b=>b.onclick=()=>{if(!canUseService('shop'))return;const it=sh.items[+b.dataset.buy];if(!it||it.sold)return;const p=buyP(it);if(gold<p)return;gold-=p;it.sold=1;gainItem(Object.assign({},it,{sold:undefined}));persist();sTone(900,1500,.15,.12,'triangle');renderEditor();});
  const sb=el.querySelector('[data-stone]');if(sb)sb.onclick=()=>{if(!canUseService('shop'))return;const p=stoneP();if(gold<p||!sh.stoneLeft)return;gold-=p;stones++;sh.stoneLeft--;saveEq();sTone(660,1980,.2,.12,'triangle');renderEditor();};}
const ENH=[100,100,100,95,90,80,70,60,50,40,35,30,25,20,15];
const enhRate=it=>Math.max(5,Math.min(100,ENH[it.plus||0]+MD().enh));
const enhCost=it=>({g:Math.round(60*((it.plus||0)+1)*(1+it.lv*.25)*RAR[it.r].m*MD().price),s:1+Math.floor((it.plus||0)/3)});
let enhMsg=null;
function renderEnh(){const el=document.getElementById('enh');if(!canUseService('enh')){el.innerHTML='';return;}
  const all=[...SLOTS.map(k=>eq[k]).filter(Boolean),...bag];if(enhSel&&!all.includes(enhSel))enhSel=null;if(!enhSel)enhSel=all[0]||null;
  let box='<p class="sub">ยังไม่มีอุปกรณ์</p>';
  if(enhSel){const it=enhSel,pl=it.plus||0;
    if(pl>=15)box=`<div class="enhbox"><img class="big" src="assets/${iicon(it)}.webp"><div><b style="font-size:20px;color:${RAR[it.r].c}">${iname(it)}</b><br>ตีบวกสูงสุดแล้ว! ${istat(it)}</div></div>`;
    else{const nx=Object.assign({},it,{plus:pl+1}),c=enhCost(it),rate=enhRate(it),brk=pl>=MD().breakAt;const can=gold>=c.g&&stones>=c.s;
      box=`<div class="enhbox"><img class="big" src="assets/${iicon(it)}.webp"><div style="flex:1;min-width:220px">
        <b style="font-size:20px;color:${RAR[it.r].c}">${iname(it)} → +${pl+1}</b><br>${istatTxt(it)}<br><span style="color:#7fdc4a">→ ${istatTxt(nx)}</span><br>
        โอกาสสำเร็จ <b style="color:${rate>=70?'#7fdc4a':rate>=40?'#ffd76a':'#ff5b6e'}">${rate}%</b> · ${brk?'<span style="color:#ff5b6e">ล้มเหลวจะลดลง 1 ขั้น</span>':'ล้มเหลวขั้นไม่ลด (เสียแค่วัตถุดิบ)'}<br>
        ใช้ <b class="price">${c.g.toLocaleString()} G</b> + หินตีบวก <b style="color:#d8c2ff">${c.s}</b> ก้อน (มี ${stones})</div>
        <div style="text-align:center"><button class="go" id="bEnh" ${can?'':'disabled style="opacity:.4"'}>🔨 ตีบวก!</button><div class="enhres" id="enhRes" style="color:${enhMsg&&enhMsg.ok?'#7fdc4a':'#ff5b6e'}">${enhMsg?enhMsg.t:''}</div></div></div>`;}}
  el.innerHTML=`<div class="npc"><img src="assets/npc_smith.webp"><div><b>ช่างตีเหล็ก:</b> ตีได้ถึง +15! ยิ่งสูงยิ่งเสี่ยงนะ ${MD().breakAt<99?`ตั้งแต่ +${MD().breakAt} ขึ้นไป ถ้าพังจะลดขั้น`:'โหมดง่ายพังยังไงขั้นก็ไม่ลด'}</div></div>${box}
    <h3>เลือกอุปกรณ์</h3><div class="bag">${all.map((it,i)=>itemCard(it,eq[it.slot]===it?'สวมอยู่':null,'',`data-pick="${i}"`,it===enhSel?'sel':'')).join('')}</div>`;
  el.querySelectorAll('[data-pick]').forEach(c=>c.onclick=()=>{enhSel=all[+c.dataset.pick];enhMsg=null;renderEditor();});
  const be=document.getElementById('bEnh');if(be)be.onclick=()=>{if(!canUseService('enh')||!enhSel||(enhSel.plus||0)>=15)return;const it=enhSel,c=enhCost(it);if(gold<c.g||stones<c.s)return;gold-=c.g;stones-=c.s;
    const pl=it.plus||0;if(Math.random()*100<enhRate(it)){it.plus=pl+1;enhMsg={ok:1,t:'สำเร็จ! +'+it.plus};sTone(600,1800,.35,.18,'triangle');setTimeout(()=>sTone(900,2400,.3,.12,'triangle'),120);}
    else{if(pl>=MD().breakAt){it.plus=pl-1;enhMsg={ok:0,t:'ล้มเหลว… ลดเหลือ +'+it.plus};}else enhMsg={ok:0,t:'ล้มเหลว…'};sTone(300,60,.5,.25,'sawtooth');}
    P.maxHp=maxHpOf();saveEq();renderEditor();};}
function renderEditor(){
  document.querySelectorAll('.tabs button').forEach(b=>{b.hidden=!canOpenTab(b.dataset.t);b.classList.toggle('on',!b.hidden&&b.dataset.t===curTab);});document.querySelectorAll('.tab').forEach(t=>t.classList.toggle('on',t.id==='tab-'+curTab));
  document.getElementById('hubTitle').textContent=afterEdit==='resume'?'⏸ พักเกม':afterEdit==='town'?'🏯 เมือง — '+CLS[cls].n:'🏯 เมือง — '+CLS[cls].n+' · ก่อนลุยด่าน '+stage;
  document.getElementById('mGold').textContent=gold.toLocaleString();document.getElementById('mStone').textContent=stones;const mm=document.getElementById('mMode');mm.textContent='โหมด '+MD().n;mm.style.color=MD().col;
  renderEquip();renderShop();renderEnh();
  const pal=document.getElementById('palette');pal.innerHTML='';const cap=capOf();
  ORDER.forEach((id,i)=>{const s=SK[id],un=isUnlocked(id);const d=document.createElement('div');d.className='card'+(un?'':' locked');
    d.innerHTML=`<img src="assets/${icId(id)}.webp" class="ic" style="${icCss(id)}"><span class="t">${s.dur} วิ</span><b>${un?'':'🔒 '}${s.name}</b><small>${un?s.desc:'ผ่านด่าน '+needStage(i)+' เพื่อปลดล็อก'}</small>`;
    d.style.borderLeft='4px solid '+(un?s.col:'#333');
    d.onclick=()=>{if(!un)return;if(chainTime()+s.dur>cap+1e-6){flashBar();return;}chain.push(id);renderEditor();};pal.appendChild(d);});
  const ch=document.getElementById('chain');ch.innerHTML='';
  if(!chain.length)ch.innerHTML='<span style="color:#6f6690;font-size:13px">ยังว่าง — กดการ์ดด้านบนเพื่อเพิ่ม</span>';
  chain.forEach((id,i)=>{const prev=chain[i-1];const syn=SYN.find(s=>s[0]===prev&&s[1]===id);const c=document.createElement('div');c.className='chip'+(syn&&found.has(syn[2])?' syn':'');
    c.innerHTML=`<i>${i+1}</i><img src="assets/${icId(id)}.webp" style="${icCss(id)}">${SK[id].name}`;c.title='กดเพื่อลบ';c.onclick=()=>{chain.splice(i,1);renderEditor();};ch.appendChild(c);});
  const t=chainTime();document.getElementById('ctime').textContent=t.toFixed(1)+' / '+cap+' วิ';document.getElementById('cbar').style.width=Math.min(100,t/cap*100)+'%';
  document.getElementById('syns').innerHTML=SYN.map(s=>found.has(s[2])?`✨ ${SK[s[0]].name} → ${SK[s[1]].name} = <b style="color:#ffd76a">${s[2]} ×${s[3]}</b>`:`❓ ??? → ??? <span style="color:#6f6690">(ลองเรียงสกิลคู่กันดู)</span>`).join('<br>');
  document.getElementById('bGo').textContent=afterEdit==='resume'?'กลับไปเล่น ▶':afterEdit==='town'?'กลับไปเดินในเมือง ▶':'ออกเดินทาง ด่าน '+stage+' ▶';
}
function flashBar(){const b=document.getElementById('cbar');b.style.background='#ff4d4d';setTimeout(()=>b.style.background='',250);}
document.getElementById('bClear').onclick=()=>{chain=[];renderEditor();};
document.getElementById('bFill').onclick=()=>{const cap=capOf(),av=ORDER.filter(isUnlocked);chain=[];let guard=0;
  while(guard++<400){const fit=av.filter(id=>chainTime()+SK[id].dur<=cap);if(!fit.length)break;
    const prev=chain[chain.length-1];const syn=SYN.filter(s=>s[0]===prev&&fit.includes(s[1]));
    chain.push(syn.length&&Math.random()<.5?syn[0][1]:fit[Math.floor(Math.random()*fit.length)]);}renderEditor();};
document.getElementById('bGo').onclick=closeEditor;

if(/[?&]debug/.test(location.search))window.__mc={P,get enemies(){return enemies},get eeT(){return eeT},get energy(){return energy},set energy(v){energy=v},get state(){return state},get scene(){return scene},get stage(){return stage},startStage,makeEnemy,add(e){enemies.push(e);return e;},loadClass,setMode(m){mode=m;},startTutorial,get tut(){return tut},TS,setChain(a){chain=a;},setStage(n){stage=n;},get kills(){return kills},set kills(v){kills=v},get run(){return run},get finale(){return finale}};
window.MAHA_VERSION='2026-11-23e';
window.__dbg=()=>({drops:drops.length,bag:bag.length,eq:Object.values(eq).filter(Boolean).length,kills,enemies:enemies.length,types:[...new Set(enemies.map(e=>e.type))]});
function loadClass(c,fresh){cls=c;ORDER=ORDERS[c];SYN=SYNS[c];const sv=fresh?null:readSave(c);
  save=Object.assign({stage:1,chain:CLS[c].def.slice(),found:[]},sv||{});
  stage=save.stage;chain=Array.isArray(save.chain)?save.chain.slice():[];found=new Set(save.found||[]);
  mode=save.mode||null;eq=save.eq||{weapon:makeItem('weapon',0,1)};bag=save.bag||[];normAll();restoreCombo();gold=save.gold||0;stones=save.stones||0;
  P.maxHp=maxHpOf();P.hp=P.maxHp;enhSel=null;}
const csEl=document.getElementById('classSel'),msEl=document.getElementById('modeSel');
function openClassSel(){edEl.classList.remove('show');msEl.classList.remove('show');state='edit';
  const el=document.getElementById('classes');el.innerHTML=Object.entries(CLS).map(([k,c])=>{const sv=readSave(k);
    return`<div class="cls" data-c="${k}" style="border-color:${c.col}"><div class="pic"><img src="assets/${c.kp}run0.webp"></div><b style="color:${c.col}">${c.n}</b><small>${c.desc}<br>HP พื้นฐาน ${c.hp} · สกิล ${ORDERS[k].length} ท่า</small>
      <div class="sv">${sv&&sv.mode?`เซฟเดิม: ด่าน ${sv.stage} · โหมด ${MODE[sv.mode].n} · ${(sv.gold||0).toLocaleString()} G`:'ยังไม่เคยเล่น'}</div></div>`;}).join('');
  el.querySelectorAll('[data-c]').forEach(d=>d.onclick=()=>{loadClass(d.dataset.c);sTone(500,1000,.15,.1,'triangle');csEl.classList.remove('show');openModeSel(false);});
  csEl.classList.add('show');}
function openModeSel(changeOnly){const sv=readSave(cls);const has=sv&&sv.mode;
  document.getElementById('modeTitle').textContent=(changeOnly?'เปลี่ยนโหมดความยาก — ':'เลือกระดับความยาก — ')+CLS[cls].n;
  document.getElementById('modeSub').textContent=changeOnly?'เปลี่ยนแล้วมีผลตั้งแต่ด่านถัดไป ของและเงินยังอยู่ครบ':has?'มีเซฟเดิมอยู่ เล่นต่อได้เลย หรือเลือกโหมดเพื่อเริ่มใหม่ (เซฟเดิมของอาชีพนี้จะหาย)':'เปลี่ยนได้ภายหลังในหน้าวิธีเล่น';
  document.getElementById('cont').innerHTML=(!changeOnly&&has)?`<div class="card" id="bCont"><b style="color:#ffd76a">▶ เล่นต่อ</b><small>ด่าน ${sv.stage} · โหมด ${MODE[sv.mode].n} · ${(sv.gold||0).toLocaleString()} G · หินตีบวก ${sv.stones||0}</small></div>`:'';
  const el=document.getElementById('modes');el.innerHTML=Object.entries(MODE).map(([k,m])=>`<div class="card" data-m="${k}" style="border-left:4px solid ${m.col}"><b style="color:${m.col}">${(!changeOnly&&has?'เริ่มใหม่ · ':'')+m.n}</b><small>${m.desc}</small></div>`).join('');
  const bc=document.getElementById('bCont');if(bc)bc.onclick=()=>{msEl.classList.remove('show');if(!tutSeen())startTutorial();else openHub('ยินดีต้อนรับกลับ '+CLS[cls].n+'!');};
  el.querySelectorAll('[data-m]').forEach(c=>c.onclick=()=>{
    if(!changeOnly&&has&&c.dataset.c!=='1'){el.querySelectorAll('[data-m]').forEach(x=>x.dataset.c='');c.dataset.c='1';c.querySelector('small').textContent='กดอีกครั้งเพื่อยืนยันเริ่มใหม่ (เซฟเดิมของ'+CLS[cls].n+'จะหาย)';return;}
    if(!changeOnly)loadClass(cls,true);mode=c.dataset.m;saveEq();msEl.classList.remove('show');if(!changeOnly&&!tutSeen())startTutorial();else openHub(CLS[cls].n+' · โหมด '+MD().n+' — จัดคอมโบแล้วออกเดินทางได้เลย');});
  edEl.classList.remove('show');state='edit';msEl.classList.add('show');}
document.getElementById('tutSkip').onclick=e=>{e.stopPropagation();if(tut)finishTutorial(true);};
document.getElementById('bTut').onclick=()=>{activeNpc=null;edEl.classList.remove('show');save.chain=chain;saveEq();startTutorial();};
document.getElementById('bMode').onclick=()=>openModeSel(true);
document.getElementById('bClass').onclick=()=>{saveEq();openClassSel();};
document.getElementById('bReset').onclick=()=>{const b=document.getElementById('bReset');if(b.dataset.c!=='1'){b.dataset.c='1';b.textContent='กดอีกครั้งเพื่อยืนยัน (ลบเซฟของอาชีพนี้)';return;}
  try{localStorage.removeItem('mahacombo-'+cls);if(cls==='sword')localStorage.removeItem('combo-proto');}catch(e){}location.reload();};
// ===== บทสอนเล่น (ขึ้นหลังเลือกอาชีพ + โหมด ครั้งแรก) =====
const tutSeen=()=>{try{return localStorage.getItem('mahacombo-tut')==='1';}catch(e){return false;}};
const KEYT=isTouch?{move:'◀ ▶',jump:'⤒',atk:'⚔️',dodge:'💨',core:'◆',skill:'★',edit:'☰',skip:'ปุ่ม ข้าม'}:{move:'A / D',jump:'S',atk:'Z',dodge:'Shift',core:'F',skill:'X',edit:'C',skip:'Esc'};
function tutFoe(type,dx,opt){const e=makeEnemy(Math.max(60,Math.min(WORLD_W-60,P.x+dx)),type,false);Object.assign(e,opt||{});e.aggro=true;e.tut=1;enemies.push(e);
  for(let i=0;i<14;i++)parts.push({x:e.x+rand(-30,30),y:GY-rand(0,e.h),vx:rand(-120,120),vy:rand(-260,-60),life:.5,max:.5,col:'#b98cff',sz:rand(3,6),g:0});return e;}
const tutAlive=()=>enemies.filter(e=>!e.dead&&!e.doomed&&e.tut).length;
const TSTEPS=[
 {id:'move',t:'เดิน',d:()=>`กด ${KEYT.move} เดินไปทางขวาสักหน่อย`,k:'move',done:T=>T.moved>260},
 {id:'jump',t:'กระโดด',d:()=>`กด ${KEYT.jump} เพื่อกระโดด`,k:'jump',done:T=>TS.jump>T.b.jump},
 {id:'atk',t:'ฟัน',d:()=>`กด ${KEYT.atk} ฟันผีน้อยให้หมด (กดค้างได้)`,k:'atk',setup(){for(let i=0;i<3;i++)tutFoe('ghost',220+i*70,{hp:18,max:18,hpLag:18,acd:9});},done:()=>tutAlive()===0},
 {id:'dodge',t:'หลบ',d:()=>`กด ${KEYT.dodge} พุ่งหลบ — ระหว่างพุ่งจะไม่โดนตี (กดพร้อมทิศทางได้)`,k:'dodge',done:T=>TS.dodge>T.b.dodge},
 {id:'ee',t:'หลบเฉียดฉิว',d:()=>`ศัตรูจะง้างตัวเป็นสีแดงก่อนตี — รอจน<b>แสงวาบสีขาว</b>แล้วกด ${KEYT.dodge}!`,k:'dodge',
  setup(){if(!tutAlive())tutFoe('skel',230,{hp:9999,max:9999,hpLag:9999,acd:1});},keep(){if(!tutAlive())this.setup();},done:T=>TS.ee>T.b.ee},
 {id:'cnt',t:'สวนกลับ',d:()=>`เวลาช้าลงแล้ว! กด ${KEYT.atk} เพื่อ "เงาวาร์ป" ฟันสวน`,k:'atk',done:T=>TS.cnt>T.b.cnt,
  keep(T){if(eeT<=0&&!P.cnt&&TS.cnt<=T.b.cnt){T.back=1;}}},
 {id:'core',t:'Core Attack',d:()=>`ฟันธรรมดาเติมเกจ Core (แถบสีทอง) ให้เต็ม แล้วกด ${KEYT.core}`,k:'core',
  setup(){for(const e of enemies)if(e.tut)e.dead=true;P.core=Math.max(P.core,70);for(let i=0;i<4;i++)tutFoe('ghost',200+i*60,{acd:9});},keep(){if(!tutAlive()&&P.core<100)for(let i=0;i<3;i++)tutFoe('ghost',180+i*60,{acd:9});},done:T=>TS.core>T.b.core},
 {id:'brk',t:'Break',d:()=>`ยักษ์มีเกจ <b style="color:#7ff3ff">Break</b> สีฟ้า — ตีจนเต็มแล้วมันจะล้ม · มันไม่สะดุ้งตอนง้าง ต้องหลบ!`,k:'atk',
  setup(){const y=tutFoe('yak',300,{acd:1.5});y.hp=y.max=y.hpLag=y.max*4;y.brkV=y.brkMax*.4;P.core=100;},keep(){if(!enemies.some(e=>e.tut&&!e.dead&&e.type==='yak'))this.setup();},done:T=>TS.brk>T.b.brk},
 {id:'combo',t:'ปล่อยคอมโบ',d:()=>`ฟัน หลบ Break ล้วนเติมเกจพลัง — เต็มแล้ว! กด ${KEYT.skill} ปล่อยคอมโบยาว`,k:'skill',
  setup(){energy=100;for(let i=0;i<5;i++)tutFoe('ghost',160+i*80,{acd:9});},keep(){if(!run&&!finale&&TS.fin<=this._b&&energy<100)energy=100;},done:T=>TS.fin>T.b.fin&&!finale&&!bigTotal},
 {id:'end',t:'จบบทสอน',d:()=>`เก่งมาก! กด ${KEYT.edit} จัดลำดับสกิลในคอมโบได้ทุกเมื่อ — ไปเมืองกันเลย`,k:'edit',done:T=>T.t>3},
];
function startTutorial(){startStage();WORLD_W=2400;portalX=99999;enemies=[];drops=[];energy=0;P.x=300;quota=0;
  tut={i:-1,t:0,moved:0,wait:0,b:{}};nextTut();banner={t:'บทสอนเล่น — '+CLS[cls].n,col:'#ffd76a',life:2,max:2};
  const sk=document.getElementById('tutSkip');if(sk)sk.style.display='block';}
function nextTut(){tut.i++;tut.t=0;tut.back=0;tut.b=Object.assign({},TS);const st=TSTEPS[tut.i];if(!st)return finishTutorial(false);st._b=TS.fin;if(st.setup)st.setup();}
function finishTutorial(skipped){try{localStorage.setItem('mahacombo-tut','1');}catch(e){}tut=null;const sk=document.getElementById('tutSkip');if(sk)sk.style.display='none';
  eeT=0;P.cnt=null;openHub(skipped?'ข้ามบทสอนแล้ว — เปิดดูอีกครั้งได้ที่ C → วิธีเล่น':'🎉 จบบทสอน! จัดคอมโบที่ฤๅษี แล้วออกเดินทางทางขวา');}
function updateTut(rdt,dt){const T=tut,st=TSTEPS[T.i];if(!st)return;T.t+=rdt;
  if((keys.left||keys.right)&&Math.abs(P.vx)>60)T.moved+=Math.abs(P.vx)*dt;
  if(T.wait>0){T.wait-=rdt;if(T.wait<=0)nextTut();return;}
  if(st.keep)st.keep.call(st,T);
  if(T.back){T.i-=2;say('ช้าไปนิด — ลองหลบเฉียดฉิวอีกครั้ง','#ff8a8a',1.8);nextTut();return;}
  if(st.done(T)){T.wait=st.id==='end'?.01:st.id==='ee'?.05:.9;if(st.id!=='end'){texts.push({x:P.x,y:P.y-200,vy:-70,txt:'สำเร็จ!',col:'#7dff9a',sz:28,life:.9,max:.9,lab:1,pop:.15});osc('triangle',660,1320,.18,.12,.3);setTimeout(()=>osc('triangle',990,1980,.2,.1,.3),90);}}}
// ช่วยจังหวะในบทสอน: ตอนแสงวาบ ศัตรูจะช้าลงให้กดทัน
const tutAssist=()=>tut&&TSTEPS[tut.i]&&TSTEPS[tut.i].id==='ee'&&!tut.wait&&eeT<=0&&enemies.some(e=>e.wind>0&&e.wind<=perfWin());
function drawTut(){const st=TSTEPS[tut.i];if(!st)return;const n=TSTEPS.length,pw=560,px=(W-pw)/2,py=156,done=tut.wait>0&&st.id!=='end';
  ctx.save();ctx.fillStyle='rgba(12,8,26,.82)';ctx.fillRect(px,py,pw,70);ctx.fillStyle=done?'#7dff9a':'#ffd76a';ctx.fillRect(px,py,4,70);
  for(let i=0;i<n;i++){ctx.fillStyle=i<tut.i||(i===tut.i&&done)?'#7dff9a':i===tut.i?'#ffd76a':'#3a3058';ctx.fillRect(px+pw-14-(n-i)*16,py+10,12,5);}
  txt('บทสอน '+(tut.i+1)+'/'+n+' · '+st.t,px+16,py+24,17,done?'#7dff9a':'#ffd76a','left',800);
  const d=st.d().replace(/<[^>]+>/g,'');txt(d,px+16,py+52,14,'#f1ecff','left',700);
  ctx.restore();
  if(!isTouch)txt('Esc = ข้าม',W-18,82,12,'#8d83aa','right',700);
  if(tutAssist()){const k=1+.1*Math.sin(t0*30);ctx.save();ctx.translate(W/2,268);ctx.scale(k,k);txt('กด '+KEYT.dodge+' เลย!',0,0,34,'#fff7c0','center',900);ctx.restore();}}

// ===== หน้าปก =====
const titleEl=document.getElementById('title');
(()=>{const em=document.getElementById('embers');for(let i=0;i<28;i++){const s=document.createElement('span');s.style.left=Math.random()*100+'%';s.style.setProperty('--dx',(Math.random()*120-60)+'px');
  s.style.animationDuration=(5+Math.random()*7)+'s';s.style.animationDelay=(-Math.random()*10)+'s';const z=2+Math.random()*4;s.style.width=s.style.height=z+'px';em.appendChild(s);}})();
let started=false;
function startFromTitle(){if(started)return;started=true;ac();musicStart();sTone(220,880,.35,.2,'triangle');setTimeout(()=>sBoom(.5),120);titleEl.style.transition='opacity .5s';titleEl.style.opacity='0';
  setTimeout(()=>{titleEl.classList.remove('show');openClassSel();},450);}
document.getElementById('bStart').onclick=e=>{e.stopPropagation();startFromTitle();};titleEl.onclick=startFromTitle;
state='title';
loadAssets(()=>{requestAnimationFrame(loop);});
})();
