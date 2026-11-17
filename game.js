// ฟันมันส์ — คอมโบสกิลยาว
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
};
const ORDER=['slash','upper','dash','slam','spin','wave','naga','rain','chakra','thunder','fire','clone','pillar','thousand','lotus','vortex','xslash','giant'];
const CAP=[6,10,15,22,32,45,60];
const SYN=[['slash','upper','ฟันเสยต่อเนื่อง',1.5],['upper','slam','ทุบดาวตก',2.5],['dash','thousand','พันดาบเงา',2],['spin','rain','พายุฝนดาบ',1.8],
 ['thunder','wave','คลื่นสายฟ้า',2],['naga','fire','นาคเพลิง',2],['upper','pillar','เสาส่งฟ้า',2],['clone','xslash','กากบาทพันเงา',2.2],
 ['lotus','thousand','บัวพันกลีบ',2],['vortex','giant','ทัณฑ์สวรรค์',3]];

let save={stage:1,chain:['slash','upper','dash','slash'],found:[],test:false};
try{const s=JSON.parse(localStorage.getItem('combo-proto')||'null');if(s&&s.chain)save=Object.assign(save,s);}catch(e){}
function persist(){try{localStorage.setItem('combo-proto',JSON.stringify(save));}catch(e){}}
let stage=save.stage,chain=save.chain.filter(id=>SK[id]),found=new Set(save.found),testMode=!!save.test;
const unlockedN=()=>testMode?ORDER.length:Math.min(ORDER.length,1+2*stage);
const needStage=i=>Math.floor((i-1)/2);
const capOf=()=>testMode?60:CAP[Math.min(stage-1,CAP.length-1)];
const isUnlocked=id=>ORDER.indexOf(id)<unlockedN();
const chainTime=()=>chain.reduce((a,id)=>a+SK[id].dur,0);

// ================= ภาพ =================
const IMG={};
const ASSETS=['bg',...[0,1,2,3].map(i=>'h_atk'+i),...[0,1,2,3,4,5].map(i=>'h_run'+i),...[0,1,2,3,4,5,6,7].map(i=>'h_sp'+i),
 ...[0,1,2,3].map(i=>'g'+i),...[0,1,2,3].map(i=>'y'+i),...[0,1,2,3].map(i=>'s'+i),...[0,1,2,3].map(i=>'b'+i),...[0,1,2,3].map(i=>'o'+i),...['weapon','armor','charm'].flatMap(k=>[0,1,2].map(r=>'it_'+k+r)),
 'ui_coin','ui_stone','npc_merchant','npc_smith','fx_slashG','fx_slashC','fx_burst','fx_shock','fx_giant','fx_naga','fx_chakra','fx_lotus','fx_fire','fx_pillar',...ORDER.map(i=>'ic_'+i)];
function loadAssets(cb){let n=ASSETS.length;ASSETS.forEach(k=>{const i=new Image();i.onload=i.onerror=()=>{if(--n===0)cb();};i.src='assets/'+k+'.webp';IMG[k]=i;});}
const ok=im=>im&&im.complete&&im.naturalWidth>0;
const TC={};function tint(im,col){const k=im.src+col;if(TC[k])return TC[k];const c=document.createElement('canvas');c.width=im.naturalWidth||1;c.height=im.naturalHeight||1;const g=c.getContext('2d');g.drawImage(im,0,0);g.globalCompositeOperation='source-atop';g.fillStyle=col;g.fillRect(0,0,c.width,c.height);return TC[k]=c;}
// ขนาดเฟรม (หน่วยพิกเซลในเกม) และจุดเท้า ax
const FM={
 h_atk:[{w:124,h:171,ax:.536},{w:129,h:147,ax:.384},{w:199,h:138,ax:.337},{w:157,h:149,ax:.389}],
 h_run:[{w:135,h:147,ax:.452},{w:137,h:147,ax:.467},{w:125,h:140,ax:.556},{w:137,h:141,ax:.412},{w:127,h:146,ax:.366},{w:125,h:147,ax:.352}],
 h_sp:[{w:109,h:179,ax:.5},{w:112,h:183,ax:.5},{w:168,h:150,ax:.372},{w:187,h:121,ax:.324},{w:122,h:198,ax:.549},{w:145,h:143,ax:.493},{w:144,h:150,ax:.444},{w:150,h:162,ax:.653}],
 g:[{w:77,h:69,ax:.5},{w:76,h:85,ax:.5},{w:74,h:74,ax:.5},{w:72,h:68,ax:.5}],
 s:[{w:101,h:117,ax:.703},{w:99,h:118,ax:.707},{w:103,h:117,ax:.665},{w:103,h:119,ax:.665}],
 b:[{w:85,h:93,ax:.5},{w:87,h:75,ax:.5},{w:86,h:76,ax:.5},{w:85,h:75,ax:.5}],
 o:[{w:131,h:171,ax:.481},{w:130,h:171,ax:.427},{w:129,h:168,ax:.496},{w:126,h:171,ax:.54}],
 y:[{w:109,h:140,ax:.495},{w:106,h:139,ax:.448},{w:109,h:141,ax:.514},{w:108,h:138,ax:.56}]};
const cyc=(arr,fps)=>arr[Math.floor(t0*fps)%arr.length];
function heroFrame(){const p=P;
  if(p.finisher>0)return['h_sp',7];
  if(finale&&finale.phase===2&&!finale.result&&p.blink!==undefined)return[['h_atk',2],['h_sp',2],['h_sp',3],['h_atk',3],['h_sp',0],['h_sp',1]][p.blink%6];
  if(p.hurt>0&&!run)return['h_sp',6];
  if(run){const id=chain[run.i],t=run.t,st=run.st;
    switch(id){
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
    }}
  if(p.atkA>0){const k=1-p.atkA/p.atkMax;
    if(p.atkStep===0)return['h_atk',Math.min(3,Math.floor(k*4))];
    if(p.atkStep===1)return k<.3?['h_atk',1]:['h_sp',2];
    return k<.25?['h_atk',0]:(k<.75?['h_sp',3]:['h_atk',3]);}
  if(!p.ground)return['h_run',p.vy<0?4:3];
  if(Math.abs(p.vx)>60)return['h_run',2+Math.floor(t0*12)%4];
  return['h_run',Math.floor(t0*2.5)%2];}

// ================= มอนสเตอร์ =================
const ET={
 ghost:{gold:5,name:'ผีน้อย',fk:'g',hp:30,w:46,h:62,sp:[95,150],dmg:8,kb:1,fps:8,hover:1,drop:.12,gib:['#7fdc4a','#ffcf4a','#3f9a2a'],mm:'#7fdc4a'},
 skel:{gold:7,name:'ทหารโครงกระดูก',fk:'s',hp:48,w:50,h:105,sp:[120,165],dmg:10,kb:.9,fps:9,drop:.15,gib:['#f1e6c8','#ffcf4a','#8a6a3a'],mm:'#f1e6c8'},
 bird:{gold:6,name:'ปักษาไฟ',fk:'b',hp:28,w:62,h:52,sp:[150,200],dmg:9,kb:1.1,fps:11,fly:1,drop:.13,gib:['#ff7a3d','#ffcf4a','#ff3d1f'],mm:'#ff9a3d'},
 yak:{gold:18,name:'ยักษ์',fk:'y',hp:130,w:72,h:118,sp:[60,80],dmg:14,kb:.5,fps:7,drop:.35,gib:['#c8202e','#ffcf4a','#7a1018'],mm:'#ff5b6e'},
 golem:{gold:60,name:'ยักษ์หินทวารบาล',fk:'o',hp:420,w:100,h:165,sp:[40,55],dmg:22,kb:.22,fps:5,drop:1,gib:['#9a948a','#ffcf4a','#5a554e'],mm:'#c9c2b8'},
};
const MODE={
 easy:{n:'ง่าย',col:'#7fdc4a',hp0:.75,grow:1.22,dmg:.6,gold:1.5,stone:1.7,drop:1.4,price:.75,enh:12,breakAt:99,desc:'มอนเลือดน้อย เงินและหินดรอปเยอะ ของถูก ตีบวกไม่มีวันลดขั้น'},
 normal:{n:'ปกติ',col:'#5fb8ff',hp0:1,grow:1.35,dmg:1,gold:1,stone:1,drop:1,price:1,enh:0,breakAt:10,desc:'สมดุล ตีบวกตั้งแต่ +10 ขึ้นไป ถ้าล้มเหลวจะลดลง 1 ขั้น'},
 hard:{n:'ยาก',col:'#ff5b6e',hp0:1.3,grow:1.5,dmg:1.45,gold:.8,stone:.7,drop:.8,price:1.3,enh:-10,breakAt:7,desc:'มอนเลือดหนา ตีแรง ของแพง หินหายาก ตีบวกตั้งแต่ +7 ล้มเหลวลดขั้น'}};
let mode=save.mode||null;const MD=()=>MODE[mode||'normal'];
const hpScale=()=>MD().hp0*Math.pow(MD().grow,stage-1);
function pickType(){const w={ghost:5,skel:stage>=1?3:0,bird:stage>=2?3:1.2,yak:1+stage*.3,golem:stage>=3?.25+.12*stage:(stage===2?.15:0)};
  let t=Math.random()*Object.values(w).reduce((a,b)=>a+b,0);for(const k in w){t-=w[k];if(t<=0)return k;}return 'ghost';}

// ================= อุปกรณ์ =================
const RAR=[{n:'ธรรมดา',c:'#d6dbe4',m:1},{n:'หายาก',c:'#5fb8ff',m:1.6},{n:'ตำนาน',c:'#ffb02e',m:2.5}];
const SLOTN={weapon:'อาวุธ',armor:'เกราะ',charm:'เครื่องราง'};
const INAME={weapon:['ดาบเหล็กกล้า','ดาบเงินนาคา','ดาบทองเทวะ'],armor:['เสื้อเกราะหนัง','เกราะเงินลายไทย','เกราะทองสุริยะ'],charm:['ตะกรุดทองแดง','พระเครื่องเงิน','แก้วมณีโชติ']};
function makeItem(slot,r,lv){const m=RAR[r].m,rand=(a,b)=>a+Math.random()*(b-a);const it={slot,r,lv,name:INAME[slot][r]};
  if(slot==='weapon')it.atk=Math.round(lv*22*m*rand(.9,1.1));
  if(slot==='armor'){it.hp=Math.round(lv*28*m*rand(.9,1.1));it.def=Math.min(60,Math.round((4+lv*2.2)*m));}
  if(slot==='charm'){it.crit=Math.round((3+lv*1.3)*m);it.en=Math.round((8+lv*2)*m);}
  return it;}
const pm=it=>1+(it.plus||0)*.12+Math.max(0,(it.plus||0)-9)*.1;
const S=(it,k)=>k==='def'?Math.min(75,Math.round(it.def*(1+(it.plus||0)*.04))):Math.round(it[k]*pm(it));
const iname=it=>it.name+(it.plus?' +'+it.plus:'');
const iscore=it=>!it?0:it.slot==='weapon'?S(it,'atk'):it.slot==='armor'?S(it,'hp')+S(it,'def')*8:S(it,'crit')*8+S(it,'en')*3;
const istat=it=>it.slot==='weapon'?`โจมตี +${S(it,'atk')}%`:it.slot==='armor'?`HP +${S(it,'hp')} · ลดดาเมจ ${S(it,'def')}%`:`คริ +${S(it,'crit')}% · เกจ +${S(it,'en')}%`;
let eq=save.eq||{weapon:makeItem('weapon',0,1),armor:null,charm:null},bag=save.bag||[];
const atkMul=()=>1+(eq.weapon?S(eq.weapon,'atk')/100:0);
const maxHpOf=()=>100+(eq.armor?S(eq.armor,'hp'):0);
const defOf=()=>eq.armor?S(eq.armor,'def')/100:0;
const critOf=()=>.12+(eq.charm?S(eq.charm,'crit')/100:0);
const enMul=()=>1+(eq.charm?S(eq.charm,'en')/100:0);
let gold=save.gold||0,stones=save.stones||0;
function saveEq(){save.eq=eq;save.bag=bag;save.gold=gold;save.stones=stones;save.mode=mode;persist();}
function gainItem(it){const cur=eq[it.slot];let msg;
  if(iscore(it)>iscore(cur)){eq[it.slot]=it;if(cur)bag.unshift(cur);msg='สวมใส่แล้ว!';if(it.slot==='armor'){P.maxHp=maxHpOf();P.hp=Math.min(P.maxHp,P.hp+S(it,'hp'));}}
  else{bag.unshift(it);msg='เก็บเข้ากระเป๋า';}
  if(bag.length>15){bag.sort((a,b)=>iscore(b)-iscore(a));bag.length=15;}
  saveEq();pickups.push({it,msg,life:2.6,max:2.6});if(pickups.length>4)pickups.shift();}
function equipFromBag(i){const it=bag[i];if(!it)return;const cur=eq[it.slot];eq[it.slot]=it;bag.splice(i,1);if(cur)bag.unshift(cur);P.maxHp=maxHpOf();P.hp=Math.min(P.hp,P.maxHp);saveEq();}

// ================= เสียง =================
let AC=null,muted=false,noise=null,lastSnd=0;
function ac(){if(!AC){try{AC=new (window.AudioContext||window.webkitAudioContext)();const n=AC.sampleRate*.4;noise=AC.createBuffer(1,n,AC.sampleRate);const d=noise.getChannelData(0);for(let i=0;i<n;i++)d[i]=Math.random()*2-1;}catch(e){AC=null}}if(AC&&AC.state==='suspended')AC.resume();return AC;}
function nz(freq,q,v,dur,type='bandpass'){const a=AC;if(!a||muted)return;const t=a.currentTime;const s=a.createBufferSource();s.buffer=noise;const f=a.createBiquadFilter();f.type=type;f.frequency.value=freq;f.Q.value=q;
  const g=a.createGain();g.gain.setValueAtTime(v,t);g.gain.exponentialRampToValueAtTime(.001,t+dur);s.connect(f).connect(g).connect(a.destination);s.start(t);s.stop(t+dur+.02);}
function sHit(p=1,v=.14){const a=AC;if(!a||muted)return;if(a.currentTime-lastSnd<.028)return;lastSnd=a.currentTime;nz(1500*p*(.8+Math.random()*.4),1.4,v,.09);}
function sTone(f0,f1,dur,v=.3,type='sine'){const a=AC;if(!a||muted)return;const t=a.currentTime;const o=a.createOscillator();o.type=type;o.frequency.setValueAtTime(f0,t);o.frequency.exponentialRampToValueAtTime(Math.max(1,f1),t+dur);
  const g=a.createGain();g.gain.setValueAtTime(v,t);g.gain.exponentialRampToValueAtTime(.001,t+dur);o.connect(g).connect(a.destination);o.start(t);o.stop(t+dur);}
function sBoom(v=.7){sTone(140,28,.9,v);nz(700,.7,v*.9,.35,'lowpass');}
function sSwish(){nz(3200,.8,.18,.12,'highpass');}

// ================= สถานะ =================
const P={x:200,y:GY,vx:0,vy:0,face:1,hp:100,maxHp:100,inv:0,atkCD:0,atkStep:0,swing:0,ground:true,atkA:0,atkMax:1,hurt:0,land:0,finisher:0,curKey:'',prevKey:'',swT:0};
let enemies=[],parts=[],fxs=[],projs=[],texts=[],trail=[],drops=[],pickups=[];
let energy=0,kills=0,quota=30,spawnT=0,state='edit',afterEdit='start',doomedN=0;
let timeScale=1,hitstop=0,shake=0,zoom=1,zoomT=1,desat=0,desatT=0,flash=0,dark=0,darkT=0,chroma=0,blackT=0;
let run=null,finale=null,bigTotal=null,banner=null,toast=null,t0=0,cracks=null;
let goldT=0,WORLD_W=4200,camX=0,portalX=4000;
const keys={};
const rand=(a,b)=>a+Math.random()*(b-a);
const dmgScale=()=>1+.22*(stage-1);

// ================= ปุ่ม =================
// ใช้ e.code = ปุ่มจริงบนคีย์บอร์ด กดได้แม้เปิดภาษาไทยอยู่
const KM={ArrowLeft:'left',KeyA:'left',ArrowRight:'right',KeyD:'right',KeyS:'jump',ArrowUp:'jump',KeyW:'jump',Space:'jump',KeyZ:'atk',KeyX:'skill'};
addEventListener('keydown',e=>{ac();const c=e.code;const k=KM[c];
  if(state==='edit'||state==='msg'){if(document.getElementById('modeSel').classList.contains('show'))return;if(c==='Enter'||c==='KeyC'||c==='Space'){e.preventDefault();if(state==='edit')closeEditor();else document.getElementById('mGo').click();}return;}
  if(k){keys[k]=true;e.preventDefault();if(e.repeat)return;if(k==='skill')tryRelease();if(k==='jump')jump();}
  if(c==='KeyC'||c==='Tab'){e.preventDefault();if(state==='play'&&!run&&!finale)openEditor('resume');}
  if(c==='KeyV'){if(!run)energy=100;}
  if(c==='KeyM')muted=!muted;});
addEventListener('keyup',e=>{const k=KM[e.code];if(k)keys[k]=false;});
addEventListener('blur',()=>{for(const k in keys)keys[k]=false;});
addEventListener('pointerdown',()=>{ac();try{window.focus();}catch(e){}});
document.querySelectorAll('#touch .b').forEach(b=>{const k=b.dataset.k;
  b.addEventListener('pointerdown',e=>{e.preventDefault();ac();if(k==='edit'){if(state==='play'&&!run&&!finale)openEditor('resume');return;}keys[k]=true;if(k==='skill')tryRelease();if(k==='jump')jump();});
  const up=()=>keys[k]=false;b.addEventListener('pointerup',up);b.addEventListener('pointerleave',up);b.addEventListener('pointercancel',up);});
function jump(){if(state==='play'&&P.ground&&!finale&&!(run&&['slam','dash','xslash'].includes(chain[run.i]))){P.vy=-780;P.ground=false;}}

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
  let v=Math.round(base*(run?run.mult:1)*(.85+Math.random()*.3)*((opt&&opt.air&&air)?2:1)*atkMul()*(crit?2:1));
  e.hp-=v;e.hitT=.1;e.stun=.45;e.aggro=true;e.vx=kx*e.kb;if(ky){e.vy=ky*Math.min(1,e.kb+.15);e.ground=false;}
  sparks(e.x,e.y-e.h/2,run?SK[chain[run.i]].col:'#fff',crit?10:5);
  if(!run||crit||Math.random()<.25)spr('fx_burst',e.x+rand(-8,8),e.y-e.h/2,crit?150:95,rand(0,6),1,.13,1.3);
  if(!run||crit||Math.random()<.25)addText(e.x+rand(-14,14),e.y-e.h-8,v,crit);
  if(run){run.hits++;run.dmg+=v;e.marked=true;}else if(!finale){energy=Math.min(100,energy+7*enMul());}
  sHit(e.heavy?.6:1);
  if(e.hp<=0&&!e.doomed){if((run||finale)&&doomedN<50){e.doomed=true;doomedN++;}else kill(e);}
}
function hitRect(x,y,w,h,d,kx,ky,opt){let n=0;for(const e of enemies){if(e.dead)continue;if(e.x+e.w/2>x&&e.x-e.w/2<x+w&&e.y>y&&e.y-e.h<y+h){damage(e,d,typeof kx==='function'?kx(e):kx,ky,opt);n++;}}return n;}
function hitCircle(cx,cy,r,d,kxF,ky,opt){let n=0;for(const e of enemies){if(e.dead)continue;const dx=e.x-cx,dy=(e.y-e.h/2)-cy;if(dx*dx+dy*dy<(r+e.w/2)**2){damage(e,d,kxF(e),ky,opt);n++;}}return n;}
const front=(w,h,d,kx,ky,opt)=>hitRect(P.face>0?P.x-10:P.x-w+10,P.y-h,w,h,d,kx,ky,opt);
const outward=(s,cx)=>e=>Math.sign(e.x-(cx===undefined?P.x:cx)||1)*s;
const near=(r,x=P.x)=>enemies.filter(e=>!e.dead&&Math.abs(e.x-x)<r);
function kill(e,big){if(e.dead)return;e.dead=true;if(e.doomed)doomedN--;kills++;
  sparks(e.x,e.y-e.h/2,ET[e.type].gib[0],big?26:12,big?700:450);
  if(big){ring(e.x,e.y-e.h/2,10,110,'#fff',.35,6);gibs(e.x,e.y-e.h/2,e);}
  if(!run&&!finale)energy=Math.min(100,energy+4*enMul());
  const T=ET[e.type];const g=Math.max(1,Math.round(T.gold*(1+.3*(stage-1))*MD().gold*rand(.8,1.2)));gold+=g;goldT=.6;
  if(!run||Math.random()<.3)texts.push({x:e.x+rand(-10,10),y:e.y-e.h-30,vy:-120,txt:'+'+g+' G',col:'#ffd76a',sz:15,life:.7,max:.7});
  const sc={ghost:.012,skel:.018,bird:.016,yak:.06,golem:.3}[e.type]*MD().stone;if(Math.random()<sc)drops.push({x:e.x,y:e.y-e.h/2,vx:rand(-100,100),vy:-560,stone:1,t:0});
  if(Math.random()<T.drop*MD().drop*(run||finale?.6:1)&&drops.length<25){const r=Math.random();const rr=r<.05+stage*.005?2:r<.3?1:0;
    drops.push({x:e.x,y:e.y-e.h/2,vx:rand(-120,120),vy:-520,it:makeItem(['weapon','armor','charm'][Math.floor(Math.random()*3)],rr,stage),t:0});}}

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
function ghostOf(){const hf=heroFrame();return{x:P.x,y:P.y,f:P.face,k:hf[0]+hf[1],m:FM[hf[0]][hf[1]],life:.25};}

function tryRelease(){
  if(state!=='play'||run||finale)return;
  if(!chain.length){say('ยังไม่มีคอมโบ กด C เพื่อจัด','#ff8a8a');return;}
  if(energy<100){say('เกจยังไม่เต็ม — ฟันศัตรูเพื่อเติม','#ff8a8a');return;}
  energy=0;run={i:0,t:0,total:0,hits:0,dmg:0,acc:0,st:{},mult:1,dur:chainTime()};P.inv=0;beginStep();sTone(300,900,.35,.15,'triangle');
}
function beginStep(){const id=chain[run.i],prev=run.i>0?chain[run.i-1]:null;run.t=0;run.st={f0:P.face};run.mult=1;run.syn=null;run.acc=-1;
  for(const s of SYN)if(s[0]===prev&&s[1]===id){run.mult=s[3];run.syn=s[2];if(!found.has(s[2])){found.add(s[2]);save.found=[...found];persist();}
    banner={t:'คอมโบซ่อน! '+s[2]+' ×'+s[3],col:'#ffd76a',life:1.4,max:1.4};sTone(600,1200,.3,.12,'square');}
}
function updateRun(dt){const id=chain[run.i];TICK[id](dt);run.t+=dt;run.total+=dt;
  if(run.t>=SK[id].dur){if(id==='dash'||id==='xslash')P.vx=0;if(id==='spin'||id==='lotus')P.face=run.st.f0;run.i++;
    if(run.i>=chain.length)startFinale();else beginStep();}}

// ================= ฉากจบคอมโบ =================
function startFinale(){finale={t:0,hits:run.hits,dmg:run.dmg,phase:0,beats:0,slashes:[],queue:[],bonus:0,n:0};run=null;P.finisher=9;P.vx=0;
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
      P.finisher=0;timeScale=1;zoomT=1;zoom=1.12;desatT=0;desat=0;darkT=0;dark=0;flash=1;shake=36;hitstop=.1;chroma=1;cracks=crackGen();sBoom(.9);
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
      const nf=Math.sign(e.x-P.x)||1;trail.push(ghostOf());P.face=nf;P.x=Math.max(24,Math.min(WORLD_W-24,e.x-nf*65));P.y=Math.min(GY,e.y);P.vy=-60;P.blink=F.n;P.swT=t0-1;
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
  return{type,x,y:T.fly?GY-150:GY,vx:0,vy:0,w:T.w,h:T.h,hp,max:hp,heavy:T.kb<.6,kb:T.kb,speed:rand(T.sp[0],T.sp[1]),hitT:0,stun:0,ground:!T.fly,bob:rand(0,6),home:x,aggro:!wander,wt:rand(0,6),dive:0,cd:rand(1,3)};}
function populate(){enemies=[];drops=[];for(let x=700;x<WORLD_W-350;x+=rand(420,620)){const n=Math.floor(rand(3,6));for(let i=0;i<n;i++)enemies.push(makeEnemy(x+rand(-120,120),pickType(),true));}
  if(stage>=2)enemies.push(makeEnemy(portalX-260,'golem',true));}
function spawn(dt){spawnT-=dt;if(finale)return;
  const vis=enemies.filter(e=>!e.dead&&!e.doomed&&e.x>camX-500&&e.x<camX+W+500).length;
  const want=run?28:8+stage*2;const iv=Math.max(.25,1.2-.1*stage)/(run?3:1);
  if(spawnT<=0&&vis<want){spawnT=iv;let side=Math.random()<.5?-1:1;let x=side<0?camX-50:camX+W+50;
    if(x<20||x>WORLD_W-20){side=-side;x=side<0?camX-50:camX+W+50;}
    if(x<20||x>WORLD_W-20)return;let t=pickType();if(t==='golem'&&!run&&Math.random()<.6)t='yak';enemies.push(makeEnemy(x,t,false));}}
function updatePlayer(dt){
  const busy=run&&((chain[run.i]==='dash'&&run.t<.33)||(chain[run.i]==='xslash'&&run.t<.3));
  let mv=(keys.right?1:0)-(keys.left?1:0);if(P.finisher>0||(finale&&!finale.result))mv=0;
  if(!busy){const tgt=mv*340;P.vx+=(tgt-P.vx)*Math.min(1,dt*14);if(mv&&!(run&&(chain[run.i]==='spin'||chain[run.i]==='lotus')))P.face=mv;}
  const wasG=P.ground;P.vy+=1900*dt;P.x+=P.vx*dt;P.y+=P.vy*dt;
  if(P.y>=GY){P.y=GY;if(!wasG&&P.vy>300)P.land=.14;P.vy=0;P.ground=true;}else P.ground=false;
  P.x=Math.max(24,Math.min(WORLD_W-24,P.x));
  P.inv=Math.max(0,P.inv-dt);P.hurt=Math.max(0,P.hurt-dt);P.land=Math.max(0,P.land-dt);P.atkA=Math.max(0,P.atkA-dt);
  if(run&&chain[run.i]!=='dash'&&chain[run.i]!=='xslash'){if(Math.random()<.5)trail.push(ghostOf());}
  for(const t of trail)t.life-=dt;trail=trail.filter(t=>t.life>0);if(trail.length>14)trail.splice(0,trail.length-14);
  P.atkCD-=dt;P.swing=Math.max(0,P.swing-dt);
  if(keys.atk&&P.atkCD<=0&&!run&&!finale&&P.finisher<=0){P.atkCD=.19;P.atkStep=(P.atkStep+1)%3;P.swing=.12;const big=P.atkStep===2;P.atkA=P.atkMax=big?.28:.21;
    if(P.ground)P.vx+=P.face*(big?260:120);
    arc(P.x+P.face*28,P.y-78,big?92:76,big?-1.5:(P.atkStep?1.2:-1.2),big?1.4:(P.atkStep?-1.1:1.1),big?'#fff':'#dfe8ff',big?14:9,.15,P.face);
    spr('fx_slashG',P.x+P.face*(big?70:58),P.y-82,big?250:190,[0,.7,-.5][P.atkStep],P.face,big?.2:.15,1.2);sSwish();
    const n=front(big?150:130,130,big?22:12,P.face*(big?420:150),big?-340:-90);
    if(n){hitstop=Math.max(hitstop,big?.075:.045);shake=Math.max(shake,big?7:3);}}
  if(P.finisher>0)P.finisher-=dt;
  // ประตูวาร์ป
  if(kills>=quota&&!run&&!finale&&!bigTotal&&Math.abs(P.x-portalX)<60)stageClear();
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
    if((e.ground||flying)&&(e.stun>0||e.doomed))e.vx*=Math.pow(.02,dt);
    else if((e.ground||flying)&&!e.doomed){let tv;if(e.aggro)tv=Math.sign(P.x-e.x)*e.speed*(e.dive>0?1.6:1);else{e.wt+=dt;tv=Math.sin(e.wt*.8)*e.speed*.4+(e.home-e.x)*.6;}
      e.vx+=(tv-e.vx)*Math.min(1,dt*6);}
    e.x=Math.max(10,Math.min(WORLD_W-10,e.x));
    if(!run&&!finale&&P.finisher<=0&&!e.doomed&&P.inv<=0&&e.stun<=0&&Math.abs(e.x-P.x)<e.w/2+14&&Math.abs((e.y-e.h/2)-(P.y-70))<Math.max(70,e.h/2+20)){
      const dm=Math.max(1,Math.round(T.dmg*MD().dmg*(1+.18*(stage-1))*(1-defOf())));P.hp-=dm;addText(P.x,P.y-170,dm,false,true);
      P.inv=.9;P.hurt=.35;P.vx=Math.sign(P.x-e.x||1)*420;P.vy=-320;P.ground=false;shake=10;flash=Math.max(flash,.15);sTone(200,80,.2,.2,'square');}
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
    else if(p.k==='giant'){p.life-=dt;if(!p.landed){p.y+=p.vy*dt;if(p.y>=GY-210){p.y=GY-210;p.landed=true;
        hitCircle(p.x,GY-60,300,80,outward(520,p.x),-760,{air:true});spr('fx_shock',p.x,GY-80,760,0,1,.6,1.25);spr('fx_burst',p.x,GY-60,520,0,1,.4,1.4);
        ring(p.x,GY-6,20,420,'#fff1a8',.5,16);groundCrack(p.x);flash=.6;shake=30;hitstop=.13;sBoom(.9);
        for(let i=0;i<40;i++)parts.push({x:p.x+rand(-80,80),y:GY,vx:rand(-800,800),vy:rand(-700,-150),life:.8,max:.8,col:'#a98b6a',sz:rand(4,9),g:1500,solid:1});}}}
  }
  projs=projs.filter(p=>p.life>0);
}
function updateFx(dt){
  for(const f of fxs)f.life-=dt;fxs=fxs.filter(f=>f.life>0);
  for(const p of parts){p.vy+=p.g*dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.life-=dt;if(p.vr)p.rot+=p.vr*dt;if(p.solid&&p.y>GY+4){p.y=GY+4;p.vy*=-.3;p.vx*=.6;}}parts=parts.filter(p=>p.life>0);
  if(parts.length>1100)parts.splice(0,parts.length-1100);
  for(const t of texts){t.y+=t.vy*dt;t.vy*=Math.pow(.15,dt);t.life-=dt;}texts=texts.filter(t=>t.life>0);
  if(texts.length>160)texts.splice(0,texts.length-160);
}
function update(rdt){
  t0+=rdt;
  if(finale&&state==='play')updateFinale(rdt);
  zoom+=(zoomT-zoom)*Math.min(1,rdt*7);desat+=(desatT-desat)*Math.min(1,rdt*7);dark+=(darkT-dark)*Math.min(1,rdt*6);
  flash=Math.max(0,flash-rdt*2.6);shake=Math.max(0,shake-rdt*55);chroma=Math.max(0,chroma-rdt*1.6);
  if(cracks){cracks.life-=rdt;if(cracks.life<=0)cracks=null;}
  for(const o of [bigTotal,banner,toast])if(o)o.life-=rdt;for(const p of pickups)p.life-=rdt;goldT=Math.max(0,goldT-rdt);pickups=pickups.filter(p=>p.life>0);
  if(bigTotal&&bigTotal.life<=0)bigTotal=null;if(banner&&banner.life<=0)banner=null;if(toast&&toast.life<=0)toast=null;
  // กล้องตามตัวละคร
  const tx=Math.max(0,Math.min(WORLD_W-W,P.x-W/2+P.face*90));camX+=(tx-camX)*Math.min(1,rdt*5);
  if(state!=='play')return;
  if(hitstop>0){hitstop-=rdt;return;}
  const dt=rdt*timeScale;
  updatePlayer(dt);if(run)updateRun(dt);updateEnemies(dt);updateProjs(dt);updateFx(dt);spawn(dt);
  if(P.hp<=0){P.hp=0;saveEq();openHub('💀 แพ้แล้ว — เงินและของที่เก็บได้ยังอยู่ครบ ลองซื้อของหรือตีบวกแล้วลุยด่าน '+stage+' ใหม่');}
}

// ================= วาด =================
function drawBG(){const im=IMG.bg;if(!ok(im)){ctx.fillStyle='#24142e';ctx.fillRect(0,0,W,H);return;}
  const sw=im.naturalWidth,sh=im.naturalHeight,fy=sh/H;
  const tile=(off,sy,hh)=>{let i0=Math.floor(off/W);for(let i=i0;i<i0+2;i++){const x=i*W-off;ctx.save();
      if(((i%2)+2)%2){ctx.translate(x+W,0);ctx.scale(-1,1);ctx.drawImage(im,0,sy*fy,sw,hh*fy,0,sy,W,hh);}else ctx.drawImage(im,0,sy*fy,sw,hh*fy,x,sy,W,hh);ctx.restore();}};
  const sc=1.3,fw=W*sc,fh=H*sc,par=(fw-W)*Math.min(1,camX/Math.max(1,WORLD_W-W));ctx.drawImage(im,0,0,sw,sh,-par,H-fh,fw,fh);tile(camX,398,H-398);
  const g=ctx.createLinearGradient(0,388,0,412);g.addColorStop(0,'rgba(20,10,30,0)');g.addColorStop(.5,'rgba(20,10,30,.45)');g.addColorStop(1,'rgba(20,10,30,0)');ctx.fillStyle=g;ctx.fillRect(0,388,W,24);}
function drawPortal(){const x=portalX,on=kills>=quota;const y=GY-95;
  ctx.save();ctx.translate(x,y);
  ctx.globalCompositeOperation='lighter';
  for(let i=0;i<3;i++){ctx.save();ctx.rotate(t0*(i%2?-1.4:1.1)+i);ctx.strokeStyle=on?['#ffd76a','#ff8fc8','#9ef'][i]:'#555';ctx.globalAlpha=on?.8:.35;ctx.lineWidth=6-i;
    ctx.beginPath();ctx.ellipse(0,0,58+i*10,92+i*8,0,0,Math.PI*1.6);ctx.stroke();ctx.restore();}
  if(on){const g=ctx.createRadialGradient(0,0,5,0,0,90);g.addColorStop(0,'rgba(255,240,200,.9)');g.addColorStop(1,'rgba(160,80,255,0)');ctx.fillStyle=g;ctx.beginPath();ctx.ellipse(0,0,60,95,0,0,7);ctx.fill();}
  ctx.restore();
  if(!on)txt('กำจัดอีก '+(quota-kills)+' ตัว',x,y-115,14,'#ccc','center',700);else txt('↓ ประตูวาร์ป',x,y-115+Math.sin(t0*5)*4,16,'#ffd76a');}
function drawPlayer(sil){const p=P;
  const [fk,fi]=heroFrame(),m=FM[fk][fi],im=IMG[fk+fi],key=fk+fi;
  if(key!==p.curKey){p.prevKey=p.curKey;p.prevM=p.curM;p.prevF=p.face;p.curKey=key;p.curM=m;p.swT=t0;}
  if(sil){ctx.save();ctx.translate(p.x,p.y);ctx.scale(p.face,1);ctx.drawImage(tint(im,'#ffffff'),-m.w*m.ax,-m.h,m.w,m.h);ctx.restore();return;}
  ctx.fillStyle='rgba(0,0,0,.4)';ctx.beginPath();ctx.ellipse(p.x,GY+2,34,8,0,0,7);ctx.fill();
  if(p.inv>0&&!run&&p.hurt<=0&&Math.floor(p.inv*20)%2)return;
  const col=run?SK[chain[run.i]].col:(p.finisher>0?'#ffd76a':null);
  if(col){ctx.save();ctx.globalCompositeOperation='lighter';const g=ctx.createRadialGradient(p.x,p.y-75,8,p.x,p.y-75,130);g.addColorStop(0,col);g.addColorStop(1,'rgba(0,0,0,0)');
    ctx.globalAlpha=.32+.15*Math.sin(t0*20);ctx.fillStyle=g;ctx.fillRect(p.x-140,p.y-210,280,250);ctx.restore();}
  if(trail.length){ctx.save();ctx.globalCompositeOperation='lighter';for(const t of trail){ctx.globalAlpha=t.life/.25*.35;ctx.save();ctx.translate(t.x,t.y);ctx.scale(t.f,1);ctx.drawImage(tint(IMG[t.k],col||'#9ef'),-t.m.w*t.m.ax,-t.m.h,t.m.w,t.m.h);ctx.restore();}ctx.restore();}
  ctx.save();ctx.translate(p.x,p.y);
  let sy=1,sx=1;
  if(fk==='h_run'&&fi<2&&p.ground)sy=1+.014*Math.sin(t0*4);
  if(p.land>0){const k=p.land/.14;sy*=1-.13*k;sx*=1+.1*k;}
  if(p.swing>0){sx*=1.05;sy*=.97;}
  ctx.scale(sx,sy);
  // ซ้อนเฟรมก่อนหน้าจางๆ ให้ท่าต่อกันเนียนขึ้น
  const b=Math.min(1,(t0-p.swT)/.08);
  if(b<1&&p.prevKey&&IMG[p.prevKey]){ctx.save();ctx.scale(p.prevF,1);ctx.globalAlpha=(1-b)*.65;const pm=p.prevM;ctx.drawImage(IMG[p.prevKey],-pm.w*pm.ax,-pm.h,pm.w,pm.h);ctx.restore();}
  ctx.scale(p.face,1);
  ctx.drawImage(im,-m.w*m.ax,-m.h,m.w,m.h);
  if(p.hurt>0){ctx.globalAlpha=.5;ctx.drawImage(tint(im,'#ff3040'),-m.w*m.ax,-m.h,m.w,m.h);}
  ctx.restore();}
function drawEnemy(e,sil){const T=ET[e.type];
  const moving=(T.fly||e.ground)&&e.stun<=0&&!e.doomed&&(Math.abs(e.vx)>8||T.fly||T.hover);const fi=moving?Math.floor(t0*T.fps+e.bob)%4:0;const m=FM[T.fk][fi],im=IMG[T.fk+fi],w=m.w,h=m.h;
  const d=Math.sign((e.aggro?P.x:e.x+e.vx)-e.x)||1;const hover=T.hover?-10+Math.sin(t0*5+e.bob)*5:0;
  if(!sil){const sh=T.fly?Math.max(.25,1-(GY-e.y)/260):1;ctx.fillStyle=`rgba(0,0,0,${.35*sh})`;ctx.beginPath();ctx.ellipse(e.x,GY+2,e.w*.6*sh,6*sh,0,0,7);ctx.fill();}
  ctx.save();ctx.translate(e.x,e.y+hover);
  if(!e.ground&&!(T.fly&&e.stun<=0&&!e.doomed))ctx.rotate((e.vx>0?1:-1)*Math.min(1,Math.abs(e.vy)/900)*.7);
  if(T.fly&&e.dive>0)ctx.rotate(-d*.35);
  ctx.scale(d>0?-1:1,1);
  if(sil){ctx.drawImage(tint(im,'#ff1030'),-w*m.ax,-h,w,h);ctx.restore();return;}
  let src=im,ov=null;if(e.doomed)ov=tint(im,Math.floor(t0*24)%2?'#ffffff':'#ff2a4a');else if(e.hitT>0)src=tint(im,'#ffffff');
  if(e.hitT>0&&!e.doomed){const k=1+e.hitT*1.2;ctx.scale(k,2-k);}
  ctx.drawImage(src,-w*m.ax,-h,w,h);if(ov){ctx.globalAlpha=.6;ctx.drawImage(ov,-w*m.ax,-h,w,h);ctx.globalAlpha=1;}
  ctx.restore();
  if(e.hp<e.max&&!e.doomed){const bw=e.type==='golem'?80:44,y=e.y+hover-h-8;ctx.fillStyle='#000a';ctx.fillRect(e.x-bw/2,y,bw,5);ctx.fillStyle='#ff4d5e';ctx.fillRect(e.x-bw/2,y,bw*Math.max(0,e.hp/e.max),5);}
  if(e.type==='golem'&&!e.doomed)txt(T.name,e.x,e.y-h-16,12,'#e8e2d8','center',700);
}
function drawDrops(){for(const d of drops){if(d.stone){ctx.save();ctx.translate(d.x,d.y+Math.sin(t0*4+d.x)*3);ctx.globalCompositeOperation='lighter';const g=ctx.createRadialGradient(0,0,2,0,0,40);g.addColorStop(0,'rgba(185,140,255,.7)');g.addColorStop(1,'rgba(0,0,0,0)');ctx.fillStyle=g;ctx.fillRect(-40,-40,80,80);ctx.globalCompositeOperation='source-over';if(ok(IMG.ui_stone))ctx.drawImage(IMG.ui_stone,-18,-18,36,36);ctx.restore();continue;}
  const R=RAR[d.it.r],im=IMG['it_'+d.it.slot+d.it.r];const bob=Math.sin(t0*4+d.x)*3;
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
      ctx.strokeStyle=f.col;ctx.lineWidth=f.w*k*2.2;ctx.globalAlpha*=.35;ctx.beginPath();ctx.arc(0,0,f.r,f.a0,f.a1,f.a1<f.a0);ctx.stroke();
      ctx.globalAlpha=Math.min(1,k*1.4);ctx.strokeStyle='#fff';ctx.lineWidth=f.w*k*.7;ctx.beginPath();ctx.arc(0,0,f.r,f.a0,f.a1,f.a1<f.a0);ctx.stroke();ctx.restore();}
    else if(f.t==='ring'){const r=f.r1+(f.r0-f.r1)*k;ctx.strokeStyle=f.col;ctx.lineWidth=f.w*k;ctx.beginPath();ctx.ellipse(f.x,f.y,r,r*(f.y>GY-30?.3:1),0,0,7);ctx.stroke();}
    else if(f.t==='line'){ctx.strokeStyle=f.col;ctx.lineWidth=f.w*k;ctx.beginPath();ctx.moveTo(f.x1,f.y1);ctx.lineTo(f.x2,f.y2);ctx.stroke();}
    else if(f.t==='bolt'){ctx.strokeStyle=f.col;ctx.lineWidth=7*k;ctx.beginPath();f.pts.forEach((p,i)=>i?ctx.lineTo(p[0],p[1]):ctx.moveTo(p[0],p[1]));ctx.stroke();ctx.strokeStyle='#fff';ctx.lineWidth=2.5;ctx.stroke();}
    else if(f.t==='spr'){const im=IMG[f.name];if(!ok(im))continue;const sz=f.size*(1+(f.grow-1)*(1-k));ctx.save();ctx.globalCompositeOperation='lighter';ctx.globalAlpha=f.alpha*Math.min(1,k*1.8);ctx.translate(f.x,f.y);ctx.scale(f.flip,1);ctx.rotate(f.rot);ctx.drawImage(im,-sz/2,-sz/2,sz,sz);ctx.restore();}
    else if(f.t==='gcrack'){ctx.save();ctx.globalAlpha=Math.min(1,k*2);ctx.strokeStyle='#1a0d10';ctx.lineWidth=4;for(const s of f.seg){ctx.beginPath();ctx.moveTo(f.x,GY+4);ctx.lineTo(f.x+s[0]*180*s[1],GY+4+s[1]*40);ctx.stroke();}
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
    else if(p.k==='giant'){ctx.save();ctx.globalCompositeOperation='lighter';ctx.globalAlpha=Math.min(1,p.life*2);ctx.drawImage(IMG.fx_giant,p.x-230,p.y-230,460,460);ctx.restore();}
  }
  ctx.globalAlpha=1;
  for(const p of parts){ctx.globalAlpha=Math.min(1,p.life/p.max*1.5);ctx.fillStyle=p.col;
    if(p.solid){ctx.globalCompositeOperation='source-over';if(p.rot!==undefined){ctx.save();ctx.translate(p.x,p.y);ctx.rotate(p.rot);ctx.fillRect(-p.sz/2,-p.sz/3,p.sz,p.sz*.66);ctx.restore();}else ctx.fillRect(p.x-p.sz/2,p.y-p.sz/2,p.sz,p.sz);}
    else{ctx.globalCompositeOperation='lighter';ctx.fillRect(p.x-p.sz/2,p.y-p.sz/2,p.sz,p.sz);}}
  ctx.globalCompositeOperation='source-over';ctx.globalAlpha=1;ctx.textAlign='center';
  for(const t of texts){ctx.globalAlpha=Math.min(1,t.life/t.max*2);ctx.font=`900 ${t.sz}px system-ui,sans-serif`;ctx.lineWidth=t.sz>30?6:4;ctx.strokeStyle='#000';ctx.strokeText(t.txt,t.x,t.y);ctx.fillStyle=t.col;ctx.fillText(t.txt,t.x,t.y);}
  ctx.globalAlpha=1;
}
function txt(s,x,y,size,col,align='center',w=900){ctx.font=`${w} ${size}px system-ui,"Noto Sans Thai",sans-serif`;ctx.textAlign=align;ctx.lineWidth=Math.max(3,size/7);ctx.strokeStyle='rgba(0,0,0,.85)';ctx.strokeText(s,x,y);ctx.fillStyle=col;ctx.fillText(s,x,y);}
function drawHUD(){
  ctx.fillStyle='#000a';ctx.fillRect(16,16,224,14);ctx.fillStyle='#ff5b6e';ctx.fillRect(18,18,220*P.hp/P.maxHp,10);
  const full=energy>=100&&!run&&!finale;
  ctx.fillStyle='#000a';ctx.fillRect(16,52,224,14);ctx.fillStyle=full?`hsl(${t0*300%360},90%,65%)`:'#6a8cff';ctx.fillRect(18,54,220*energy/100,10);
  txt('HP '+Math.max(0,Math.ceil(P.hp))+'/'+P.maxHp,246,29,12,'#fff','left',700);txt('พลังโจมตี ×'+atkMul().toFixed(2),18,112,13,'#ffcf9a','left',700);{const gs=1+goldT*.5;if(ok(IMG.ui_coin))ctx.drawImage(IMG.ui_coin,16,122,22,22);ctx.save();ctx.translate(42,139);ctx.scale(gs,gs);txt(gold.toLocaleString(),0,0,15,'#ffd76a','left',800);ctx.restore();if(ok(IMG.ui_stone))ctx.drawImage(IMG.ui_stone,120,122,22,22);txt(''+stones,146,139,15,'#d8c2ff','left',800);txt(MD().n,190,139,12,MD().col,'left',800);}
  pickups.forEach((p,i)=>{if(p.stone){const a=Math.min(1,p.life/p.max*3),y=H-120-i*40;ctx.globalAlpha=a;ctx.fillStyle='rgba(15,10,25,.8)';ctx.fillRect(W-330,y-24,312,36);ctx.fillStyle='#b98cff';ctx.fillRect(W-330,y-24,4,36);if(ok(IMG.ui_stone))ctx.drawImage(IMG.ui_stone,W-322,y-21,30,30);txt('หินตีบวก +1 (มี '+stones+')',W-286,y+2,15,'#d8c2ff','left',800);ctx.globalAlpha=1;return;}const R=RAR[p.it.r],a=Math.min(1,p.life/p.max*3),y=H-120-i*40;ctx.globalAlpha=a;ctx.fillStyle='rgba(15,10,25,.8)';ctx.fillRect(W-330,y-24,312,36);ctx.fillStyle=R.c;ctx.fillRect(W-330,y-24,4,36);
    const im=IMG['it_'+p.it.slot+p.it.r];if(ok(im))ctx.drawImage(im,W-322,y-21,30,30);txt(iname(p.it)+' ('+R.n+')',W-286,y-6,14,R.c,'left',800);txt(istat(p.it)+' · '+p.msg,W-286,y+9,11,'#ddd','left',600);ctx.globalAlpha=1;});txt('พลัง',246,65,12,'#cfd8ff','left',700);if(full)txt((isTouch?'★':'X')+' ปล่อยคอมโบ '+chainTime().toFixed(1)+' วิ!',18,92,16,'#ffd76a','left');
  txt('ด่าน '+stage+(testMode?' (ทดลอง)':''),W-18,32,18,'#fff','right');
  txt('กำจัด '+Math.min(kills,quota)+' / '+quota,W-18,56,15,kills>=quota?'#ffd76a':'#cfc6e8','right',700);
  if(!isTouch&&!run&&!finale)txt('C จัดคอมโบ · V เติมเกจ',W-18,78,12,'#8d83aa','right',600);
  if(!run&&!finale&&!bigTotal){const mw=300,mx=(W-mw)/2,my=24;ctx.fillStyle='rgba(10,6,20,.6)';ctx.fillRect(mx-6,my-8,mw+12,16);ctx.fillStyle='#4a3d66';ctx.fillRect(mx,my-1,mw,2);
    for(const e of enemies){if(e.dead)continue;ctx.fillStyle=ET[e.type].mm;ctx.fillRect(mx+e.x/WORLD_W*mw-1,my-3,2,6);}
    ctx.fillStyle=kills>=quota?'#ffd76a':'#888';ctx.beginPath();ctx.arc(mx+portalX/WORLD_W*mw,my,5,0,7);ctx.fill();
    ctx.fillStyle='#fff';ctx.beginPath();ctx.arc(mx+P.x/WORLD_W*mw,my,4,0,7);ctx.fill();
    if(kills>=quota)txt('ไปที่ประตูวาร์ป →',W/2,54,15,'#ffd76a');}
  if(run){const bw=420,bx=(W-bw)/2,by=20;ctx.fillStyle='#000b';ctx.fillRect(bx-4,by-4,bw+8,22);let x=bx;
    chain.forEach((id,i)=>{const w=bw*SK[id].dur/run.dur;ctx.fillStyle=i<run.i?'#555':i===run.i?SK[id].col:'#2a2240';ctx.globalAlpha=i===run.i?1:.85;ctx.fillRect(x+1,by,w-2,14);x+=w;});
    ctx.globalAlpha=1;const px=bx+bw*Math.min(1,run.total/run.dur);ctx.fillStyle='#fff';ctx.fillRect(px-1.5,by-4,3,22);
    const id=chain[run.i];const ic=IMG['ic_'+id];const pk=1+Math.max(0,.25-run.t)*1.6;ctx.save();ctx.translate(W/2,74);ctx.scale(pk,pk);if(ok(ic))ctx.drawImage(ic,-30,-30,60,60);ctx.restore();
    txt(SK[id].name+(run.syn?'  ×'+run.mult:''),W/2,132,24,run.syn?'#ffd76a':SK[id].col);
    txt((run.dur-run.total).toFixed(1)+' วิ',W/2,152,14,'#cfc6e8','center',700);
    const s=1+.12*Math.sin(t0*30);ctx.save();ctx.translate(W-30,140);ctx.scale(s,s);txt(run.hits+' HIT',0,0,40,'#ffd76a','right');ctx.restore();
    txt(run.dmg.toLocaleString()+' DMG',W-30,168,16,'#fff','right',700);}
  if(!isTouch&&!run&&!finale&&!bigTotal){const ks=[['A D','เดิน'],['S','กระโดด'],['Z','ฟัน'],['X','คอมโบ'],['C','จัดคอมโบ']];let x=16;ctx.font='700 13px system-ui,sans-serif';
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
const fxC=document.createElement('canvas'),fxG=fxC.getContext('2d');
function postChroma(){const w=cv.width,h=cv.height;if(fxC.width!==w){fxC.width=w;fxC.height=h;}const d=Math.round(chroma*14*dpr);
  ctx.save();ctx.setTransform(1,0,0,1,0,0);
  for(const [c,o] of [['#ff0000',d],['#00ffff',-d]]){fxG.globalCompositeOperation='source-over';fxG.drawImage(cv,0,0);fxG.globalCompositeOperation='multiply';fxG.fillStyle=c;fxG.fillRect(0,0,w,h);
    ctx.globalCompositeOperation='lighter';ctx.globalAlpha=.35*chroma;ctx.drawImage(fxC,o,0);}
  ctx.restore();}
function speedLines(a){ctx.save();ctx.globalAlpha=a;ctx.strokeStyle='#fff';ctx.lineWidth=2;const cx=W/2,cy=H/2;for(let i=0;i<46;i++){const ang=rand(0,6.3),r0=rand(260,380),r1=r0+rand(160,320);
  ctx.beginPath();ctx.moveTo(cx+Math.cos(ang)*r0,cy+Math.sin(ang)*r0*.75);ctx.lineTo(cx+Math.cos(ang)*r1,cy+Math.sin(ang)*r1*.75);ctx.stroke();}ctx.restore();}
function render(){
  ctx.setTransform(dpr,0,0,dpr,0,0);
  const sx=(Math.random()-.5)*shake,sy=(Math.random()-.5)*shake;
  const psx=P.x-camX;const k=Math.max(0,Math.min(1,(zoom-1)/.4));const fx=W/2+(psx-W/2)*k,fy=H/2+(P.y-90-H/2)*k;
  ctx.save();ctx.translate(W/2+sx,H/2+sy);ctx.scale(zoom,zoom);ctx.translate(-fx,-fy);
  drawBG();
  ctx.translate(-camX,0);
  drawPortal();
  for(const e of enemies)if(e.x>camX-200&&e.x<camX+W+200)drawEnemy(e);
  drawDrops();drawVortex();drawPlayer();drawFx();
  ctx.restore();
  if(desat>.01){ctx.globalCompositeOperation='saturation';ctx.fillStyle=`rgba(128,128,128,${desat})`;ctx.fillRect(0,0,W,H);ctx.globalCompositeOperation='source-over';}
  if(dark>.01||desat>.01){const vg=ctx.createRadialGradient(W/2,H/2,H*.22,W/2,H/2,H*.8);vg.addColorStop(0,`rgba(40,0,0,${dark*.2})`);vg.addColorStop(1,`rgba(0,0,0,${Math.min(.92,desat*.6+dark)})`);ctx.fillStyle=vg;ctx.fillRect(0,0,W,H);}
  if(finale&&finale.phase===0)speedLines(.25+finale.t*.3);
  if(blackT>0&&finale&&finale.phase===1){ctx.fillStyle='#000';ctx.fillRect(0,0,W,H);ctx.save();ctx.translate(W/2,H/2);ctx.scale(zoom,zoom);ctx.translate(-fx,-fy);ctx.translate(-camX,0);
    for(const e of enemies)if(!e.dead&&(e.marked||e.doomed))drawEnemy(e,true);drawPlayer(true);ctx.restore();}
  if(chroma>.02)postChroma();
  if(cracks){const a=Math.min(1,cracks.life/cracks.max*2);ctx.save();ctx.lineJoin='round';ctx.globalAlpha=a;
    for(const pass of [[5,'rgba(0,0,0,.55)'],[1.6,'rgba(255,255,255,.95)']]){ctx.lineWidth=pass[0];ctx.strokeStyle=pass[1];for(const c of cracks.pts){ctx.beginPath();c.forEach((p,i)=>i?ctx.lineTo(p[0],p[1]):ctx.moveTo(p[0],p[1]));ctx.stroke();}}ctx.restore();}
  if(flash>0){ctx.fillStyle=`rgba(255,255,255,${Math.min(1,flash)})`;ctx.fillRect(0,0,W,H);}
  drawHUD();
}
let last=performance.now();
function loop(now){const rdt=Math.min(.05,(now-last)/1000);last=now;update(rdt);render();requestAnimationFrame(loop);}

// ================= ลำดับเกม =================
function startStage(){projs=[];fxs=[];parts=[];texts=[];trail=[];run=null;finale=null;bigTotal=null;cracks=null;doomedN=0;timeScale=1;zoomT=1;desatT=0;darkT=0;blackT=0;
  WORLD_W=Math.min(8000,3600+600*stage);portalX=WORLD_W-160;
  P.x=150;P.y=GY;P.vx=P.vy=0;P.face=1;P.maxHp=maxHpOf();P.hp=P.maxHp;P.inv=1;P.finisher=0;kills=0;quota=testMode?40:16+6*stage;energy=testMode?100:20;spawnT=.6;camX=0;
  populate();state='play';banner={t:'ด่าน '+stage+' — ไปทางขวา →',col:'#fff',life:1.8,max:1.8};hideMsg();}
function stageClear(){const oldN=unlockedN(),oldCap=capOf();stage++;save.stage=stage;save.shop=null;saveEq();persist();
  let t='✨ ผ่านด่าน '+(stage-1)+'!';const nN=unlockedN();if(nN>oldN)t+=' · ปลดล็อกสกิล: '+ORDER.slice(oldN,nN).map(i=>SK[i].name).join(', ');
  if(capOf()>oldCap)t+=' · คอมโบยาวสุด '+capOf()+' วิ';sTone(523,1046,.4,.15,'triangle');openHub(t);}
const msgEl=document.getElementById('msg');
function showMsg(title,html,goLabel,onGo){document.getElementById('mTitle').textContent=title;document.getElementById('mText').innerHTML=html;
  const g=document.getElementById('mGo');g.textContent=goLabel;g.onclick=onGo;const me=document.getElementById('mEdit');me.onclick=()=>{hideMsg();openEditor('start');};msgEl.classList.add('show');}
function hideMsg(){msgEl.classList.remove('show');}
const edEl=document.getElementById('editor');
let curTab='skill',enhSel=null;
function openHub(note){afterEdit='start';document.getElementById('hubNote').textContent=note||'';curTab=note&&note.startsWith('✨')?'shop':curTab;openPanel();}
function openEditor(after){afterEdit=after;document.getElementById('hubNote').textContent=after==='resume'?'⏸ หยุดเกมชั่วคราว — ร้านค้ากับตีบวกใช้ได้เฉพาะในเมือง (หลังเข้าประตูวาร์ป)':'';if(after==='resume'&&(curTab==='shop'||curTab==='enh'))curTab='skill';openPanel();}
function openPanel(){state='edit';for(const k in keys)keys[k]=false;hideMsg();renderEditor();edEl.classList.add('show');}
function closeEditor(){edEl.classList.remove('show');save.chain=chain;saveEq();if(afterEdit==='resume')state='play';else startStage();}
function setTab(t){curTab=t;renderEditor();}
document.querySelectorAll('.tabs button').forEach(b=>b.onclick=()=>setTab(b.dataset.t));
const sellP=it=>Math.round(25*it.lv*(1+it.r*1.5)*(1+(it.plus||0)*.35));
function itemCard(it,label,extra,attr,cls){if(!it)return`<div class="eqc empty"><small>${label}</small><b>ว่าง</b></div>`;const R=RAR[it.r];
  return`<div class="eqc ${cls||''}" ${attr||''} style="border-color:${R.c}${attr?';cursor:pointer':''}"><img src="assets/it_${it.slot}${it.r}.webp"><div style="flex:1"><small>${label||SLOTN[it.slot]} · Lv.${it.lv} · ${R.n}</small><b style="color:${R.c}">${iname(it)}</b><span>${istat(it)}</span></div>${extra||''}</div>`;}
function renderEquip(){const el=document.getElementById('equip');
  const town=afterEdit!=='resume';
  el.innerHTML=`<div class="eqrow">${['weapon','armor','charm'].map(k=>itemCard(eq[k],SLOTN[k])).join('')}</div>
    <div class="stat">พลังโจมตี ×${atkMul().toFixed(2)} · HP สูงสุด ${maxHpOf()} · ลดดาเมจ ${Math.round(defOf()*100)}% · คริ ${Math.round(critOf()*100)}% · เกจไวขึ้น ${Math.round((enMul()-1)*100)}%</div>
    <h3>กระเป๋า (${bag.length}/15)</h3><div class="bag">${bag.map((it,i)=>itemCard(it,null,`<button data-eq="${i}">ใส่</button>${town?`<button data-sell="${i}">ขาย ${sellP(it)}G</button>`:''}`)).join('')||'<span style="color:#6f6690;font-size:13px">ยังว่าง — ฟันมอนสเตอร์ให้ดรอปของ หรือซื้อที่ร้าน</span>'}</div>`;
  el.querySelectorAll('[data-eq]').forEach(b=>b.onclick=()=>{equipFromBag(+b.dataset.eq);renderEditor();});
  el.querySelectorAll('[data-sell]').forEach(b=>b.onclick=()=>{const i=+b.dataset.sell;gold+=sellP(bag[i]);bag.splice(i,1);saveEq();sTone(1200,1800,.1,.1,'triangle');renderEditor();});}
function shopStock(){if(save.shop&&save.shop.stage===stage)return save.shop;
  const items=[];for(let i=0;i<5;i++){const q=Math.random();const r=q<.06?2:q<.4?1:0;items.push(makeItem(['weapon','armor','charm'][i%3===0?0:Math.floor(Math.random()*3)],r,stage));}
  save.shop={stage,items,stoneLeft:3};persist();return save.shop;}
const buyP=it=>Math.round(90*it.lv*Math.pow(1+it.r*1.4,1.5)*MD().price);
const stoneP=()=>Math.round(260*(1+.25*(stage-1))*MD().price);
function renderShop(){const el=document.getElementById('shop');if(afterEdit==='resume'){el.innerHTML='<p class="sub">ร้านค้าเปิดเฉพาะในเมือง — เข้าประตูวาร์ปท้ายแมพก่อนนะ</p>';return;}
  const sh=shopStock();
  el.innerHTML=`<div class="npc"><img src="assets/npc_merchant.webp"><div><b>ลุงพ่อค้า:</b> ของใหม่มาทุกด่านเลยหลาน! ด่านยิ่งลึก ของยิ่งแรง ขายของเก่าได้ที่แท็บอุปกรณ์นะ</div></div>
    <div class="shop">${sh.items.map((it,i)=>it.sold?'':itemCard(it,null,`<div class="buy"><span class="price">${buyP(it).toLocaleString()} G</span><button data-buy="${i}" ${gold<buyP(it)?'disabled style="opacity:.4"':''}>ซื้อ</button></div>`)).join('')}
    <div class="eqc" style="border-color:#b98cff"><img src="assets/ui_stone.webp"><div style="flex:1"><small>วัตถุดิบ · เหลือ ${sh.stoneLeft} ชิ้น</small><b style="color:#d8c2ff">หินตีบวก</b><span>ใช้ตีบวกอุปกรณ์</span></div><div class="buy"><span class="price">${stoneP().toLocaleString()} G</span><button data-stone ${gold<stoneP()||!sh.stoneLeft?'disabled style="opacity:.4"':''}>ซื้อ</button></div></div></div>`;
  el.querySelectorAll('[data-buy]').forEach(b=>b.onclick=()=>{const it=sh.items[+b.dataset.buy];const p=buyP(it);if(gold<p)return;gold-=p;it.sold=1;gainItem(Object.assign({},it,{sold:undefined}));persist();sTone(900,1500,.15,.12,'triangle');renderEditor();});
  const sb=el.querySelector('[data-stone]');if(sb)sb.onclick=()=>{const p=stoneP();if(gold<p||!sh.stoneLeft)return;gold-=p;stones++;sh.stoneLeft--;saveEq();sTone(660,1980,.2,.12,'triangle');renderEditor();};}
const ENH=[100,100,100,95,90,80,70,60,50,40,35,30,25,20,15];
const enhRate=it=>Math.max(5,Math.min(100,ENH[it.plus||0]+MD().enh));
const enhCost=it=>({g:Math.round(60*((it.plus||0)+1)*(1+it.lv*.25)*(1+it.r*.5)*MD().price),s:1+Math.floor((it.plus||0)/3)});
let enhMsg=null;
function renderEnh(){const el=document.getElementById('enh');if(afterEdit==='resume'){el.innerHTML='<p class="sub">ร้านตีบวกเปิดเฉพาะในเมือง</p>';return;}
  const all=[...['weapon','armor','charm'].map(k=>eq[k]).filter(Boolean),...bag];if(enhSel&&!all.includes(enhSel))enhSel=null;if(!enhSel)enhSel=all[0]||null;
  let box='<p class="sub">ยังไม่มีอุปกรณ์</p>';
  if(enhSel){const it=enhSel,pl=it.plus||0;
    if(pl>=15)box=`<div class="enhbox"><img class="big" src="assets/it_${it.slot}${it.r}.webp"><div><b style="font-size:20px;color:${RAR[it.r].c}">${iname(it)}</b><br>ตีบวกสูงสุดแล้ว! ${istat(it)}</div></div>`;
    else{const nx=Object.assign({},it,{plus:pl+1}),c=enhCost(it),rate=enhRate(it),brk=pl>=MD().breakAt;const can=gold>=c.g&&stones>=c.s;
      box=`<div class="enhbox"><img class="big" src="assets/it_${it.slot}${it.r}.webp"><div style="flex:1;min-width:220px">
        <b style="font-size:20px;color:${RAR[it.r].c}">${iname(it)} → +${pl+1}</b><br>${istat(it)}<br><span style="color:#7fdc4a">→ ${istat(nx)}</span><br>
        โอกาสสำเร็จ <b style="color:${rate>=70?'#7fdc4a':rate>=40?'#ffd76a':'#ff5b6e'}">${rate}%</b> · ${brk?'<span style="color:#ff5b6e">ล้มเหลวจะลดลง 1 ขั้น</span>':'ล้มเหลวขั้นไม่ลด (เสียแค่วัตถุดิบ)'}<br>
        ใช้ <b class="price">${c.g.toLocaleString()} G</b> + หินตีบวก <b style="color:#d8c2ff">${c.s}</b> ก้อน (มี ${stones})</div>
        <div style="text-align:center"><button class="go" id="bEnh" ${can?'':'disabled style="opacity:.4"'}>🔨 ตีบวก!</button><div class="enhres" id="enhRes" style="color:${enhMsg&&enhMsg.ok?'#7fdc4a':'#ff5b6e'}">${enhMsg?enhMsg.t:''}</div></div></div>`;}}
  el.innerHTML=`<div class="npc"><img src="assets/npc_smith.webp"><div><b>ช่างตีเหล็ก:</b> ตีได้ถึง +15! ยิ่งสูงยิ่งเสี่ยงนะ ${MD().breakAt<99?`ตั้งแต่ +${MD().breakAt} ขึ้นไป ถ้าพังจะลดขั้น`:'โหมดง่ายพังยังไงขั้นก็ไม่ลด'}</div></div>${box}
    <h3>เลือกอุปกรณ์</h3><div class="bag">${all.map((it,i)=>itemCard(it,eq[it.slot]===it?'สวมอยู่':null,'',`data-pick="${i}"`,it===enhSel?'sel':'')).join('')}</div>`;
  el.querySelectorAll('[data-pick]').forEach(c=>c.onclick=()=>{enhSel=all[+c.dataset.pick];enhMsg=null;renderEditor();});
  const be=document.getElementById('bEnh');if(be)be.onclick=()=>{const it=enhSel,c=enhCost(it);if(gold<c.g||stones<c.s)return;gold-=c.g;stones-=c.s;
    const pl=it.plus||0;if(Math.random()*100<enhRate(it)){it.plus=pl+1;enhMsg={ok:1,t:'สำเร็จ! +'+it.plus};sTone(600,1800,.35,.18,'triangle');setTimeout(()=>sTone(900,2400,.3,.12,'triangle'),120);}
    else{if(pl>=MD().breakAt){it.plus=pl-1;enhMsg={ok:0,t:'ล้มเหลว… ลดเหลือ +'+it.plus};}else enhMsg={ok:0,t:'ล้มเหลว…'};sTone(300,60,.5,.25,'sawtooth');}
    P.maxHp=maxHpOf();saveEq();renderEditor();};}
function renderEditor(){
  document.querySelectorAll('.tabs button').forEach(b=>b.classList.toggle('on',b.dataset.t===curTab));document.querySelectorAll('.tab').forEach(t=>t.classList.toggle('on',t.id==='tab-'+curTab));
  document.getElementById('hubTitle').textContent=afterEdit==='resume'?'⏸ พักเกม':'🏯 เมือง — ก่อนลุยด่าน '+stage;
  document.getElementById('mGold').textContent=gold.toLocaleString();document.getElementById('mStone').textContent=stones;const mm=document.getElementById('mMode');mm.textContent='โหมด '+MD().n;mm.style.color=MD().col;
  renderEquip();renderShop();renderEnh();
  const pal=document.getElementById('palette');pal.innerHTML='';const cap=capOf();
  ORDER.forEach((id,i)=>{const s=SK[id],un=isUnlocked(id);const d=document.createElement('div');d.className='card'+(un?'':' locked');
    d.innerHTML=`<img src="assets/ic_${id}.webp" class="ic"><span class="t">${s.dur} วิ</span><b>${un?'':'🔒 '}${s.name}</b><small>${un?s.desc:'ผ่านด่าน '+needStage(i)+' เพื่อปลดล็อก'}</small>`;
    d.style.borderLeft='4px solid '+(un?s.col:'#333');
    d.onclick=()=>{if(!un)return;if(chainTime()+s.dur>cap+1e-6){flashBar();return;}chain.push(id);renderEditor();};pal.appendChild(d);});
  const ch=document.getElementById('chain');ch.innerHTML='';
  if(!chain.length)ch.innerHTML='<span style="color:#6f6690;font-size:13px">ยังว่าง — กดการ์ดด้านบนเพื่อเพิ่ม</span>';
  chain.forEach((id,i)=>{const prev=chain[i-1];const syn=SYN.find(s=>s[0]===prev&&s[1]===id);const c=document.createElement('div');c.className='chip'+(syn&&found.has(syn[2])?' syn':'');
    c.innerHTML=`<i>${i+1}</i><img src="assets/ic_${id}.webp">${SK[id].name}`;c.title='กดเพื่อลบ';c.onclick=()=>{chain.splice(i,1);renderEditor();};ch.appendChild(c);});
  const t=chainTime();document.getElementById('ctime').textContent=t.toFixed(1)+' / '+cap+' วิ';document.getElementById('cbar').style.width=Math.min(100,t/cap*100)+'%';
  document.getElementById('syns').innerHTML=SYN.map(s=>found.has(s[2])?`✨ ${SK[s[0]].name} → ${SK[s[1]].name} = <b style="color:#ffd76a">${s[2]} ×${s[3]}</b>`:`❓ ??? → ??? <span style="color:#6f6690">(ลองเรียงสกิลคู่กันดู)</span>`).join('<br>');
  document.getElementById('bTest').textContent=testMode?'ปิดโหมดทดลอง':'โหมดทดลอง: ปลดทุกสกิล 60 วิ';
  document.getElementById('bGo').textContent=afterEdit==='resume'?'กลับไปเล่น ▶':'ออกเดินทาง ด่าน '+stage+' ▶';document.getElementById('bTest').textContent=testMode?'ปิดโหมดทดลอง':'โหมดทดลอง: ปลดทุกสกิล 60 วิ';
}
function flashBar(){const b=document.getElementById('cbar');b.style.background='#ff4d4d';setTimeout(()=>b.style.background='',250);}
document.getElementById('bClear').onclick=()=>{chain=[];renderEditor();};
document.getElementById('bFill').onclick=()=>{const cap=capOf(),av=ORDER.filter(isUnlocked);chain=[];let guard=0;
  while(guard++<400){const fit=av.filter(id=>chainTime()+SK[id].dur<=cap);if(!fit.length)break;
    const prev=chain[chain.length-1];const syn=SYN.filter(s=>s[0]===prev&&fit.includes(s[1]));
    chain.push(syn.length&&Math.random()<.5?syn[0][1]:fit[Math.floor(Math.random()*fit.length)]);}renderEditor();};
document.getElementById('bTest').onclick=()=>{testMode=!testMode;save.test=testMode;persist();while(chainTime()>capOf())chain.pop();chain=chain.filter(isUnlocked);
  if(afterEdit==='resume')afterEdit='start';renderEditor();};
document.getElementById('bGo').onclick=closeEditor;

window.__dbg=()=>({drops:drops.length,bag:bag.length,eq:Object.values(eq).filter(Boolean).length,kills,enemies:enemies.length,types:[...new Set(enemies.map(e=>e.type))]});
function openModeSel(){const el=document.getElementById('modes');el.innerHTML=Object.entries(MODE).map(([k,m])=>`<div class="card" data-m="${k}" style="border-left:4px solid ${m.col}"><b style="color:${m.col}">${m.n}</b><small>${m.desc}</small></div>`).join('');
  el.querySelectorAll('[data-m]').forEach(c=>c.onclick=()=>{mode=c.dataset.m;saveEq();document.getElementById('modeSel').classList.remove('show');openHub('โหมด '+MD().n+' — จัดคอมโบแล้วออกเดินทางได้เลย');});
  edEl.classList.remove('show');state='edit';document.getElementById('modeSel').classList.add('show');}
document.getElementById('bMode').onclick=openModeSel;
document.getElementById('bReset').onclick=()=>{const b=document.getElementById('bReset');if(b.dataset.c!=='1'){b.dataset.c='1';b.textContent='กดอีกครั้งเพื่อยืนยัน (ลบเซฟทั้งหมด)';return;}
  try{localStorage.removeItem('combo-proto');}catch(e){}location.reload();};
loadAssets(()=>{if(!mode)openModeSel();else openHub('');requestAnimationFrame(loop);});
})();
