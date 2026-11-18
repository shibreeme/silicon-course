"use strict";
const el = id => document.getElementById(id);
function append(parent, tag, value) {
  const item = document.createElement(tag);
  item.textContent = value;
  parent.append(item);
  return item;
}
function drawChip(){
  const ctx=el("chip").getContext("2d");
  ctx.lineJoin="round";
  for(let side=0;side<4;side++){
    ctx.save(); ctx.translate(300,150);ctx.rotate(side*Math.PI/2);
    for(let n=0;n<12;n++){
      const y=(n-5.5)*10, bend=12+Math.abs(y)*0.5, reach=side%2?135:236;
      ctx.strokeStyle=n%3?"#65967a":"#bfdf86";ctx.beginPath();ctx.moveTo(76,y);
      ctx.lineTo(87+bend,y);ctx.lineTo(104+bend,y*1.45);ctx.lineTo(reach-Math.abs(y)*0.45,y*1.45);ctx.stroke();
      ctx.beginPath();ctx.arc(reach-Math.abs(y)*0.45,y*1.45,2,0,Math.PI*2);ctx.stroke();
    }ctx.restore();
  }
  ctx.fillStyle="#102e27";ctx.fillRect(221,71,158,158);ctx.strokeStyle="#c3dc99";ctx.strokeRect(221,71,158,158);
  for(let i=0;i<8;i++)for(let j=0;j<8;j++){ctx.fillStyle=["#829e67","#b9d889","#658961"][(i+j*2)%3];ctx.fillRect(235+i*16.5,85+j*16.5,13,13);}
}
drawChip();
lessons.forEach((lesson,index)=>{
  const row=append(el("list"),"details","");row.id="lesson-"+(index+1);
  const heading=append(row,"summary","");
  append(heading,"em",String(index+1).padStart(2,"0"));append(heading,"strong",lesson.title);append(heading,"span",lesson.stage);
  for(const [key,label] of [["concept","原理"],["exercise","动手实现"],["check","验收条件"]]){
    append(row,"h4",label);append(row,"p",lesson[key]);
  }
  const link=append(row,"a",lesson.source+" ↗");link.href=lesson.url;
});
function openLesson(){if(/^#lesson-\d+$/.test(location.hash)){const row=el(location.hash.slice(1));if(row)row.open=true;}}
window.addEventListener("hashchange",openLesson);openLesson();
function vector(value){
  const parts=value.trim().split(/[,，\s]+/);
  if(parts.length>256 || parts.some(x=>!/^[-+]?\d+$/.test(x)||Number(x)<-128||Number(x)>127)) throw Error("请输入 1 至 256 个 −128 到 127 之间的整数，以逗号或空格分隔。");
  return parts.map(Number);
}
function calculate(){
  try{
    const a=vector(el("a").value), b=vector(el("b").value);
    if(a.length!==b.length) throw Error("两个向量的长度需要一致。");
    let sum=0;
    el("trace").textContent=a.map((v,i)=>{sum+=v*b[i];return (i+1)+".　"+v+" × "+b[i]+" = "+v*b[i]+"　　累计 "+sum;}).join("\n");
  }catch(error){el("trace").textContent=error.message;}
}
el("run").onclick=calculate;calculate();
const key="silicon-course.projects.v1";
let projects=[];
try{const data=JSON.parse(localStorage.getItem(key));if(Array.isArray(data))projects=data.filter(x=>x&&typeof x.name==="string"&&typeof x.notes==="string");}catch{}
function displayProjects(){el("notes").replaceChildren();for(const p of projects){const card=append(el("notes"),"article","");append(card,"h3",p.name);append(card,"p",p.notes);}}
displayProjects();
el("form").onsubmit=event=>{
  event.preventDefault();const data=new FormData(event.target);
  const project={name:data.get("name").trim(),notes:data.get("notes").trim()};
  if(!project.name||!project.notes){alert("请填写项目名称及验收条件。");return;}
  const next=[project,...projects];
  try{localStorage.setItem(key,JSON.stringify(next));projects=next;displayProjects();event.target.reset();}catch{alert("浏览器无法保存项目，请检查存储权限或剩余空间。");}
};
