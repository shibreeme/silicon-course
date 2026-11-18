const signals = [
  ["PSEL", [0,1,1,1,0]], ["PENABLE",[0,0,1,1,0]], ["PREADY",[0,0,0,1,0]]
];
const phases=["空闲：PSEL 为 0，外设未被选中。","建立：地址、方向和数据就位。PENABLE 为 0。","等待：PSEL、PENABLE 均为 1，PREADY 为 0。请求保持不变。","提交：三个信号同时为 1。这一上升沿写入寄存器，写计数器加一。","返回空闲：PSEL 回落。刚才的写入只产生一次副作用。"];
const canvas=document.getElementById("wave"),range=document.getElementById("cycle");
function render(){
 const t=Number(range.value), ctx=canvas.getContext("2d");
 document.getElementById("state").textContent=phases[t];
 document.getElementById("tick").textContent=(t+1)+" / 5";
 if(!ctx)return;
 ctx.clearRect(0,0,640,248);ctx.font="16px Consolas,monospace";
 const x=i=>115+98*i;
 for(let i=0;i<5;i++){ctx.strokeStyle="#34564b";ctx.beginPath();ctx.moveTo(x(i),12);ctx.lineTo(x(i),206);ctx.stroke();ctx.fillStyle="#adc8b0";ctx.fillText("T"+i,x(i)+35,227);}
 signals.forEach(([name,values],row)=>{
   const y=53+row*64;ctx.fillStyle="#d6e8c9";ctx.fillText(name,8,y);
   ctx.strokeStyle="#c8ed88";ctx.lineWidth=2;ctx.beginPath();
   values.forEach((v,i)=>{const h=y-26*v;if(i===0)ctx.moveTo(x(i),h);else ctx.lineTo(x(i),h);ctx.lineTo(x(i+1),h);});ctx.stroke();
 });
 ctx.strokeStyle="#ffbd77";ctx.setLineDash([5,4]);ctx.beginPath();ctx.moveTo(x(t)+48,5);ctx.lineTo(x(t)+48,202);ctx.stroke();ctx.setLineDash([]);
}
range.addEventListener("input",render);render();
