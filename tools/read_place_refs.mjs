import fs from 'node:fs';
const s=fs.readFileSync('tools/.cache/update-refs/padthai-references.html','utf8');
const at=s.indexOf('window.__MOBX_STATE__');
const start=s.indexOf('{',at);
let depth=0,quote=false,escaped=false,end=start;
for(let i=start;i<s.length;i++){
  const c=s[i];
  if(quote){if(escaped)escaped=false;else if(c==='\\')escaped=true;else if(c==='"')quote=false;}
  else if(c==='"')quote=true;
  else if(c==='{')depth++;
  else if(c==='}'&&--depth===0){end=i+1;break;}
}
const d=JSON.parse(s.slice(start,end));
fs.writeFileSync('tools/.cache/update-refs/padthai-data.json',JSON.stringify(d.placePage.data,null,2));
console.log(JSON.stringify({place:d.placePage.data.mapsPlace,images:d.placePage.data.placeMetadata.images},null,2));
console.log(s.match(/<meta[^>]*og:image[^>]*>/g));
console.log([...new Set(s.match(/https[^\s"<>]+rTzPmXAZTRtJrzsWznhW2tX3pM3OxgEG[^\s"<>]*/g)||[])]);
