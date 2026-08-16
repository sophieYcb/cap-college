(function(){
  const SVG_NS='http://www.w3.org/2000/svg';

  function svgNode(name,attributes={}){
    const node=document.createElementNS(SVG_NS,name);
    Object.entries(attributes).forEach(([key,value])=>node.setAttribute(key,String(value)));
    return node;
  }

  function addSvgText(svg,text,x,y,attributes={}){
    const node=svgNode('text',{x,y,...attributes});
    node.textContent=String(text);
    svg.appendChild(node);
    return node;
  }

  function addSvgAngleLabel(svg,letter,x,y){
    addSvgText(svg,letter,x,y,{
      class:'chart-value',
      'text-anchor':'middle',
      'font-style':'italic',
      stroke:'#fff',
      'stroke-width':6,
      'paint-order':'stroke',
      'stroke-linejoin':'round'
    });
    svg.appendChild(svgNode('path',{
      d:`M ${x-7} ${y-18} L ${x} ${y-23} L ${x+7} ${y-18}`,
      fill:'none',
      stroke:'#17233f',
      'stroke-width':2,
      'stroke-linecap':'round',
      'stroke-linejoin':'round'
    }));
  }

  function createTable(rows){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual question-table-wrap';
    const table=document.createElement('table');
    table.className='question-data-table';
    const firstRow=rows[0]||[];
    const groupedAreaHeader=firstRow.length>=2&&firstRow.length%2===0&&firstRow.every((value,index)=>
      index%2===0||value===firstRow[index-1]
    )&&firstRow.every(value=>/²$/.test(value));
    if(groupedAreaHeader)table.classList.add('area-conversion-table');
    rows.forEach((row,rowIndex)=>{
      const tr=document.createElement('tr');
      if(rowIndex===0&&groupedAreaHeader){
        for(let columnIndex=0;columnIndex<row.length;columnIndex+=2){
          const cell=document.createElement('th');
          cell.colSpan=2;
          cell.scope='colgroup';
          cell.textContent=row[columnIndex];
          tr.appendChild(cell);
        }
      }else{
        row.forEach((value,columnIndex)=>{
          const cell=document.createElement(rowIndex===0||(!groupedAreaHeader&&columnIndex===0)?'th':'td');
          cell.textContent=value;
          tr.appendChild(cell);
        });
      }
      table.appendChild(tr);
    });
    wrapper.appendChild(table);
    return wrapper;
  }

  function createOperation(content){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual operation-visual';
    const operation=document.createElement('pre');
    operation.className='vertical-operation';
    operation.setAttribute('role','math');
    operation.setAttribute('aria-label',String(content).replace(/\n/g,' '));
    operation.textContent=String(content).replace(/^\r?\n/,'').replace(/\r?\n\s*$/,'');
    wrapper.appendChild(operation);
    return wrapper;
  }

  function createNamedBars(entries){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const svg=svgNode('svg',{viewBox:'0 0 560 270',role:'img','aria-label':'Diagramme en barres'});
    svg.classList.add('question-chart');
    const max=Math.max(...entries.map(entry=>entry.value),1);
    const ceiling=Math.ceil(max/5)*5||5;
    const left=55,bottom=220,top=20,width=460,height=185;
    svg.appendChild(svgNode('line',{x1:left,y1:top,x2:left,y2:bottom,class:'chart-axis'}));
    svg.appendChild(svgNode('line',{x1:left,y1:bottom,x2:left+width,y2:bottom,class:'chart-axis'}));
    for(let value=0;value<=ceiling;value+=5){
      const y=bottom-(value/ceiling)*height;
      svg.appendChild(svgNode('line',{x1:left,y1:y,x2:left+width,y2:y,class:'chart-grid'}));
      addSvgText(svg,value,left-10,y+5,{class:'chart-label','text-anchor':'end'});
    }
    const slot=width/entries.length;
    entries.forEach((entry,index)=>{
      const barWidth=Math.min(85,slot*.58);
      const x=left+index*slot+(slot-barWidth)/2;
      const barHeight=(entry.value/ceiling)*height;
      svg.appendChild(svgNode('rect',{x,y:bottom-barHeight,width:barWidth,height:barHeight,rx:6,class:`chart-bar chart-bar-${index%2+1}`}));
      addSvgText(svg,entry.label,x+barWidth/2,bottom+28,{class:'chart-label chart-category','text-anchor':'middle'});
      addSvgText(svg,entry.value,x+barWidth/2,bottom-barHeight-8,{class:'chart-value','text-anchor':'middle'});
    });
    wrapper.appendChild(svg);
    return wrapper;
  }
  function createBars(a,b){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const svg=svgNode('svg',{viewBox:'0 0 520 250',role:'img','aria-label':`Diagramme en barres : A vaut ${a}, B vaut ${b}`});
    svg.classList.add('question-chart');
    const max=Math.max(a,b);
    const ceiling=Math.ceil(max/5)*5;
    const left=55,bottom=205,top=20,width=420,height=175;
    svg.appendChild(svgNode('line',{x1:left,y1:top,x2:left,y2:bottom,class:'chart-axis'}));
    svg.appendChild(svgNode('line',{x1:left,y1:bottom,x2:left+width,y2:bottom,class:'chart-axis'}));
    for(let value=0;value<=ceiling;value+=5){
      const y=bottom-(value/ceiling)*height;
      svg.appendChild(svgNode('line',{x1:left,y1:y,x2:left+width,y2:y,class:'chart-grid'}));
      addSvgText(svg,value,left-12,y+5,{class:'chart-label','text-anchor':'end'});
    }
    [a,b].forEach((value,index)=>{
      const x=140+index*190;
      const barHeight=(value/ceiling)*height;
      svg.appendChild(svgNode('rect',{x,y:bottom-barHeight,width:105,height:barHeight,rx:6,class:`chart-bar chart-bar-${index+1}`}));
      addSvgText(svg,index===0?'A':'B',x+52,bottom+28,{class:'chart-label chart-category','text-anchor':'middle'});
      addSvgText(svg,value,x+52,bottom-barHeight-8,{class:'chart-value','text-anchor':'middle'});
    });
    wrapper.appendChild(svg);
    return wrapper;
  }

  function createPie(percent){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const svg=svgNode('svg',{viewBox:'0 0 320 220',role:'img','aria-label':`Diagramme circulaire avec un secteur coloré`});
    svg.classList.add('question-chart','question-pie-chart');
    const cx=160,cy=110,r=82;
    svg.appendChild(svgNode('circle',{cx,cy,r,class:'pie-background'}));
    if(percent>=100){
      svg.appendChild(svgNode('circle',{cx,cy,r,class:'pie-sector'}));
    }else if(percent>0){
      const angle=percent/100*Math.PI*2;
      const x=cx+r*Math.sin(angle);
      const y=cy-r*Math.cos(angle);
      const large=percent>50?1:0;
      const path=`M ${cx} ${cy} L ${cx} ${cy-r} A ${r} ${r} 0 ${large} 1 ${x} ${y} Z`;
      svg.appendChild(svgNode('path',{d:path,class:'pie-sector'}));
    }
    svg.appendChild(svgNode('circle',{cx,cy,r,class:'pie-outline'}));
    wrapper.appendChild(svg);
    return wrapper;
  }

  function createCubeStack(heights){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const rows=heights.length,columns=Math.max(...heights.map(row=>row.length));
    const description=heights.map(row=>row.join(', ')).join(' ; ');
    const svg=svgNode('svg',{viewBox:'0 0 620 370',role:'img','aria-label':'Empilement de cubes, hauteurs par rangée : '+description});
    svg.classList.add('question-chart');
    const stacks=[];
    const points=vertices=>vertices.map(point=>point.join(',')).join(' ');
    heights.forEach((row,y)=>row.forEach((height,x)=>{
      const cx=310+(x-(columns-1)/2)*105-(y-(rows-1)/2)*45;
      const groundY=(rows===1?305:315)-y*78;
      const cell=[[cx,groundY-16],[cx+30,groundY],[cx,groundY+16],[cx-30,groundY]];
      svg.appendChild(svgNode('polygon',{points:points(cell),fill:height>0?'#eef3ff':'#fff7dc',stroke:'#6d7fa8','stroke-width':2,'stroke-dasharray':height>0?'':'5 4'}));
    }));
    if(rows>1){
      addSvgText(svg,'Rangée arrière',310,55,{class:'chart-value','text-anchor':'middle'});
      addSvgText(svg,'Rangée avant',310,355,{class:'chart-value','text-anchor':'middle'});
    }
    heights.forEach((row,y)=>row.forEach((height,x)=>{if(height>0)stacks.push({x,y,height});}));
    stacks.sort((a,b)=>b.y-a.y||a.x-b.x);
    stacks.forEach(stack=>{
      const cx=310+(stack.x-(columns-1)/2)*105-(stack.y-(rows-1)/2)*45;
      const groundY=(rows===1?305:315)-stack.y*78;
      for(let level=0;level<stack.height;level++){
        const cy=groundY-(level+1)*36;
        const top=[[cx,cy-16],[cx+30,cy],[cx,cy+16],[cx-30,cy]];
        const right=[[cx,cy+16],[cx+30,cy],[cx+30,cy+36],[cx,cy+52]];
        const left=[[cx-30,cy],[cx,cy+16],[cx,cy+52],[cx-30,cy+36]];
        svg.appendChild(svgNode('polygon',{points:points(left),fill:'#cbdcff',stroke:'#334b7a','stroke-width':2}));
        svg.appendChild(svgNode('polygon',{points:points(right),fill:'#a9c4fa',stroke:'#334b7a','stroke-width':2}));
        svg.appendChild(svgNode('polygon',{points:points(top),fill:'#f5f8ff',stroke:'#334b7a','stroke-width':2}));
      }
    });
    wrapper.appendChild(svg);
    return wrapper;
  }

  function createCubeView(heights){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const svg=svgNode('svg',{viewBox:'0 0 560 290',role:'img','aria-label':'Vue de face, colonnes de hauteurs '+heights.join(', ')});
    svg.classList.add('question-chart');
    const size=42,totalWidth=heights.length*size,startX=(560-totalWidth)/2,bottom=245;
    heights.forEach((height,column)=>{
      for(let row=0;row<height;row++){
        svg.appendChild(svgNode('rect',{x:startX+column*size,y:bottom-(row+1)*size,width:size,height:size,fill:'#dbe7ff',stroke:'#334b7a','stroke-width':2}));
      }
    });
    addSvgText(svg,'Vue de face',280,275,{class:'chart-value','text-anchor':'middle'});
    wrapper.appendChild(svg);
    return wrapper;
  }

  function createTopView(rows){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const svg=svgNode('svg',{viewBox:'0 0 560 290',role:'img','aria-label':'Vue de dessus d’un empilement'});
    svg.classList.add('question-chart');
    const columns=Math.max(...rows.map(row=>row.length)),size=54;
    const startX=(560-columns*size)/2,startY=(245-rows.length*size)/2;
    rows.forEach((row,y)=>row.forEach((occupied,x)=>{
      if(occupied)svg.appendChild(svgNode('rect',{x:startX+x*size,y:startY+y*size,width:size,height:size,fill:'#dbe7ff',stroke:'#334b7a','stroke-width':3}));
    }));
    addSvgText(svg,'Vue de dessus',280,270,{class:'chart-value','text-anchor':'middle'});
    wrapper.appendChild(svg);
    return wrapper;
  }
  function createSolidGallery(entries){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const svg=svgNode('svg',{viewBox:'0 0 680 230',role:'img','aria-label':'Solides représentés : '+entries.map(entry=>entry.label).join(', ')});
    svg.classList.add('question-chart');
    const line={stroke:'#334b7a','stroke-width':3,fill:'#eef4ff','stroke-linejoin':'round'};
    const plain={stroke:'#334b7a','stroke-width':3,fill:'none'};
    const polygon=points=>svgNode('polygon',{points:points.map(point=>point.join(',')).join(' '),...line});
    entries.forEach((entry,index)=>{
      const cx=85+index*(510/Math.max(entries.length-1,1)),cy=105;
      if(entry.type==='cuboid'||entry.type==='cube'){
        const w=entry.type==='cube'?62:82,h=entry.type==='cube'?62:52,dx=24,dy=-20;
        const x1=cx-w/2,y1=cy-h/2,x2=cx+w/2,y2=cy+h/2;
        svg.appendChild(svgNode('polygon',{points:[[x1,y1],[x1+dx,y1+dy],[x2+dx,y1+dy],[x2,y1]].map(point=>point.join(',')).join(' '),fill:'#eef4ff',stroke:'#334b7a','stroke-width':3}));
        svg.appendChild(svgNode('polygon',{points:[[x2,y1],[x2+dx,y1+dy],[x2+dx,y2+dy],[x2,y2]].map(point=>point.join(',')).join(' '),fill:'#b9cff9',stroke:'#334b7a','stroke-width':3}));
        svg.appendChild(svgNode('rect',{x:x1,y:y1,width:w,height:h,fill:'#dbe7ff',stroke:'#334b7a','stroke-width':3}));
        svg.appendChild(svgNode('line',{x1:x1,y1:y1,x2:x1+dx,y2:y1+dy,...plain,'stroke-dasharray':'6 5'}));
        svg.appendChild(svgNode('line',{x1:x1+dx,y1:y1+dy,x2:x2+dx,y2:y1+dy,...plain,'stroke-dasharray':'6 5'}));
      }else if(entry.type==='cylinder'){
        svg.appendChild(svgNode('rect',{x:cx-38,y:cy-42,width:76,height:84,fill:'#eef4ff',stroke:'none'}));
        svg.appendChild(svgNode('ellipse',{cx,cy:cy-42,rx:38,ry:13,...line}));
        svg.appendChild(svgNode('ellipse',{cx,cy:cy+42,rx:38,ry:13,...line}));
        svg.appendChild(svgNode('line',{x1:cx-38,y1:cy-42,x2:cx-38,y2:cy+42,...plain}));
        svg.appendChild(svgNode('line',{x1:cx+38,y1:cy-42,x2:cx+38,y2:cy+42,...plain}));
      }else if(entry.type==='pyramid'){
        const base=[[cx-48,cy+38],[cx+18,cy+50],[cx+50,cy+25],[cx-18,cy+14]],apex=[cx,cy-58];
        svg.appendChild(polygon(base));
        base.forEach(point=>svg.appendChild(svgNode('line',{x1:apex[0],y1:apex[1],x2:point[0],y2:point[1],...plain})));
      }else if(entry.type==='triangular-prism'){
        const front=[[cx-48,cy+38],[cx-12,cy-38],[cx+22,cy+38]],shift=[34,-18];
        svg.appendChild(polygon(front));
        svg.appendChild(polygon(front.map(point=>[point[0]+shift[0],point[1]+shift[1]])));
        front.forEach(point=>svg.appendChild(svgNode('line',{x1:point[0],y1:point[1],x2:point[0]+shift[0],y2:point[1]+shift[1],...plain})));
      }
      addSvgText(svg,entry.label,cx,202,{class:'chart-value','text-anchor':'middle'});
    });
    wrapper.appendChild(svg);
    return wrapper;
  }
  function createCoordinatePlane(points){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const description=points.map(point=>point.label+'('+point.x+' ; '+point.y+')').join(', ');
    const svg=svgNode('svg',{viewBox:'0 0 540 340',role:'img','aria-label':'Repère contenant les points '+description});
    svg.classList.add('question-chart');
    const left=70,right=500,top=25,bottom=295;
    const framingPoints=[...points];
    const center=points.length>1&&/^(O|I|M|C)$/i.test(points[0].label)?points[0]:null;
    if(center){
      points.slice(1).forEach(point=>{
        framingPoints.push({x:2*center.x-point.x,y:2*center.y-point.y});
      });
    }
    const xValues=framingPoints.map(point=>point.x),yValues=framingPoints.map(point=>point.y);
    const minX=Math.min(0,...xValues)-1,maxX=Math.max(0,...xValues)+1;
    const minY=Math.min(0,...yValues)-1,maxY=Math.max(0,...yValues)+1;
    const xFor=value=>left+((value-minX)/(maxX-minX))*(right-left);
    const yFor=value=>bottom-((value-minY)/(maxY-minY))*(bottom-top);
    for(let value=Math.ceil(minX);value<=Math.floor(maxX);value++){
      const x=xFor(value);
      svg.appendChild(svgNode('line',{x1:x,y1:top,x2:x,y2:bottom,class:'chart-grid'}));
      addSvgText(svg,value,x,yFor(0)+22,{class:'chart-label','text-anchor':'middle'});
    }
    for(let value=Math.ceil(minY);value<=Math.floor(maxY);value++){
      const y=yFor(value);
      svg.appendChild(svgNode('line',{x1:left,y1:y,x2:right,y2:y,class:'chart-grid'}));
      if(value!==0)addSvgText(svg,value,xFor(0)-12,y+5,{class:'chart-label','text-anchor':'end'});
    }
    svg.appendChild(svgNode('line',{x1:left,y1:yFor(0),x2:right,y2:yFor(0),class:'chart-axis'}));
    svg.appendChild(svgNode('line',{x1:xFor(0),y1:top,x2:xFor(0),y2:bottom,class:'chart-axis'}));
    points.forEach(point=>{
      const x=xFor(point.x),y=yFor(point.y);
      svg.appendChild(svgNode('circle',{cx:x,cy:y,r:7,class:'chart-point'}));
      addSvgText(svg,point.label,x+12,y-10,{class:'chart-value'});
    });
    wrapper.appendChild(svg);
    return wrapper;
  }
  function createCodedTriangle(type){
    const normalized=String(type||'').trim().toLowerCase();
    const right=normalized==='right'||normalized==='right-isosceles';
    const isosceles=normalized==='isosceles'||normalized==='right-isosceles';
    const equilateral=normalized==='equilateral';
    const points=right
      ?(normalized==='right-isosceles'
        ?{A:{x:110,y:240},B:{x:110,y:65},C:{x:285,y:240}}
        :{A:{x:100,y:240},B:{x:100,y:55},C:{x:370,y:240}})
      :{A:{x:230,y:42},B:{x:110,y:250},C:{x:350,y:250}};
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const descriptions={
      isosceles:'Triangle ABC avec les côtés AB et AC codés égaux',
      equilateral:'Triangle ABC avec les trois côtés codés égaux',
      right:'Triangle ABC rectangle en A',
      'right-isosceles':'Triangle ABC rectangle en A avec AB et AC codés égaux'
    };
    const svg=svgNode('svg',{viewBox:'0 0 460 300',role:'img','aria-label':descriptions[normalized]||'Triangle ABC codé'});
    svg.classList.add('question-chart');
    [['A','B'],['B','C'],['C','A']].forEach(([from,to])=>{
      svg.appendChild(svgNode('line',{
        x1:points[from].x,y1:points[from].y,
        x2:points[to].x,y2:points[to].y,
        class:'chart-axis'
      }));
    });
    const addTick=(from,to)=>{
      const p1=points[from],p2=points[to];
      const mx=(p1.x+p2.x)/2,my=(p1.y+p2.y)/2;
      const dx=p2.x-p1.x,dy=p2.y-p1.y,length=Math.hypot(dx,dy)||1;
      const px=-dy/length*9,py=dx/length*9;
      svg.appendChild(svgNode('line',{
        x1:mx-px,y1:my-py,x2:mx+px,y2:my+py,
        stroke:'#3158df','stroke-width':4,'stroke-linecap':'round'
      }));
    };
    if(equilateral){
      addTick('A','B');addTick('B','C');addTick('C','A');
    }else if(isosceles){
      addTick('A','B');addTick('A','C');
    }
    if(right){
      svg.appendChild(svgNode('path',{
        d:`M ${points.A.x} ${points.A.y-22} L ${points.A.x+22} ${points.A.y-22} L ${points.A.x+22} ${points.A.y}`,
        fill:'none',stroke:'#3158df','stroke-width':4
      }));
    }
    const labelOffsets=right
      ?{A:[-20,24],B:[-18,-10],C:[12,24]}
      :{A:[0,-14],B:[-16,24],C:[14,24]};
    Object.entries(points).forEach(([label,point])=>{
      const offset=labelOffsets[label];
      addSvgText(svg,label,point.x+offset[0],point.y+offset[1],{class:'chart-value','text-anchor':'middle'});
    });
    wrapper.appendChild(svg);
    return wrapper;
  }

  function createAngleDiagram(measure){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const svg=svgNode('svg',{viewBox:'0 0 420 280',role:'img','aria-label':'Angle de '+measure+' degrés'});
    svg.classList.add('question-chart');
    const cx=145,cy=220,length=180,angle=measure*Math.PI/180;
    const endX=cx+length*Math.cos(-angle),endY=cy+length*Math.sin(-angle);
    svg.appendChild(svgNode('line',{x1:cx,y1:cy,x2:cx+length,y2:cy,class:'chart-axis'}));
    svg.appendChild(svgNode('line',{x1:cx,y1:cy,x2:endX,y2:endY,class:'chart-axis'}));
    const radius=62,arcX=cx+radius*Math.cos(-angle),arcY=cy+radius*Math.sin(-angle);
    svg.appendChild(svgNode('path',{d:'M '+(cx+radius)+' '+cy+' A '+radius+' '+radius+' 0 '+(measure>180?1:0)+' 0 '+arcX+' '+arcY,fill:'none',stroke:'#3158df','stroke-width':4}));
    const labelAngle=-angle/2;
    addSvgText(svg,measure+'°',cx+92*Math.cos(labelAngle),cy+92*Math.sin(labelAngle),{class:'chart-value','text-anchor':'middle'});
    addSvgText(svg,'O',cx-15,cy+24,{class:'chart-value'});
    wrapper.appendChild(svg);
    return wrapper;
  }

  function createCrossingAngles(measure){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const svg=svgNode('svg',{viewBox:'0 0 460 280',role:'img','aria-label':'Deux droites sécantes formant quatre angles notés a chapeau, b chapeau, c chapeau et d chapeau'});
    svg.classList.add('question-chart');
    const cx=230,cy=140;
    const opening=Number.isFinite(measure)?Math.max(30,Math.min(150,measure)):110;
    const firstAngle=(-90-opening/2)*Math.PI/180;
    const secondAngle=(-90+opening/2)*Math.PI/180;
    const point=(angle,length)=>({x:cx+length*Math.cos(angle),y:cy+length*Math.sin(angle)});
    const firstStart=point(firstAngle,190),firstEnd=point(firstAngle+Math.PI,190);
    const secondStart=point(secondAngle,190),secondEnd=point(secondAngle+Math.PI,190);
    svg.appendChild(svgNode('line',{x1:firstStart.x,y1:firstStart.y,x2:firstEnd.x,y2:firstEnd.y,class:'chart-axis'}));
    svg.appendChild(svgNode('line',{x1:secondStart.x,y1:secondStart.y,x2:secondEnd.x,y2:secondEnd.y,class:'chart-axis'}));
    if(Number.isFinite(measure)){
      const arcStart=point(firstAngle,48),arcEnd=point(secondAngle,48);
      svg.appendChild(svgNode('path',{
        d:`M ${arcStart.x} ${arcStart.y} A 48 48 0 0 1 ${arcEnd.x} ${arcEnd.y}`,
        fill:'none',stroke:'#3158df','stroke-width':4
      }));
    }
    addSvgAngleLabel(svg,'a',230,82);
    addSvgAngleLabel(svg,'b',310,145);
    addSvgAngleLabel(svg,'c',230,210);
    addSvgAngleLabel(svg,'d',145,145);
    if(Number.isFinite(measure))addSvgText(svg,measure+'°',230,108,{class:'chart-label','text-anchor':'middle'});
    wrapper.appendChild(svg);
    return wrapper;
  }

  function createParallelAngles(){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const svg=svgNode('svg',{viewBox:'0 0 560 330',role:'img','aria-label':'Deux droites parallèles coupées par une sécante, avec huit angles notés de a chapeau à h chapeau'});
    svg.classList.add('question-chart');
    svg.appendChild(svgNode('line',{x1:55,y1:95,x2:505,y2:95,class:'chart-axis'}));
    svg.appendChild(svgNode('line',{x1:55,y1:235,x2:505,y2:235,class:'chart-axis'}));
    svg.appendChild(svgNode('line',{x1:155,y1:25,x2:380,y2:305,class:'chart-axis'}));
    addSvgText(svg,'(d₁)',475,82,{class:'chart-label'});
    addSvgText(svg,'(d₂)',475,222,{class:'chart-label'});
    const labels=[
      ['a',168,68],['b',244,68],['c',272,135],['d',175,135],
      ['e',270,205],['f',363,205],['g',386,277],['h',286,277]
    ];
    labels.forEach(item=>addSvgAngleLabel(svg,item[0],item[1],item[2]));
    addSvgText(svg,'(d₁) ∥ (d₂)',280,315,{class:'chart-value','text-anchor':'middle'});
    wrapper.appendChild(svg);
    return wrapper;
  }
  function createCurve(points){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const description=points.map(point=>`${point.value} à ${point.hour} h`).join(', ');
    const svg=svgNode('svg',{viewBox:'0 0 540 280',role:'img','aria-label':`Courbe : ${description}`});
    svg.classList.add('question-chart');
    const left=75,bottom=225,top=25,right=495;
    const values=points.map(point=>point.value);
    const min=Math.max(0,Math.min(...values)-3);
    const max=Math.max(...values)+3;
    const yFor=value=>bottom-((value-min)/(max-min))*(bottom-top);
    svg.appendChild(svgNode('line',{x1:left,y1:top,x2:left,y2:bottom,class:'chart-axis'}));
    svg.appendChild(svgNode('line',{x1:left,y1:bottom,x2:right,y2:bottom,class:'chart-axis'}));
    [min,...values,max].filter((v,i,a)=>a.indexOf(v)===i).forEach(value=>{
      const y=yFor(value);
      svg.appendChild(svgNode('line',{x1:left,y1:y,x2:right,y2:y,class:'chart-grid'}));
      addSvgText(svg,value,left-12,y+5,{class:'chart-label','text-anchor':'end'});
    });
    const plotted=points.map((point,index)=>{
      const x=points.length===1?285:left+100+index*((right-left-200)/(points.length-1));
      return {x,y:yFor(point.value),hour:point.hour};
    });
    svg.appendChild(svgNode('polyline',{points:plotted.map(point=>`${point.x},${point.y}`).join(' '),class:'chart-line'}));
    plotted.forEach(({x,y,hour})=>{
      svg.appendChild(svgNode('circle',{cx:x,cy:y,r:8,class:'chart-point'}));
      addSvgText(svg,`${hour} h`,x,bottom+30,{class:'chart-label chart-category','text-anchor':'middle'});
    });
    addSvgText(svg,'Valeur',20,(top+bottom)/2,{class:'chart-label chart-axis-title','text-anchor':'middle',transform:'rotate(-90 20 '+((top+bottom)/2)+')'});
    wrapper.appendChild(svg);
    return wrapper;
  }

  function piePercent(prompt){
    if(/moiti|deux quarts|demi-disque/i.test(prompt))return 50;
    if(/trois quarts/i.test(prompt))return 75;
    if(/disque entier|quatre quarts/i.test(prompt))return 100;
    if(/un quart/i.test(prompt))return 25;
    if(/un dixième/i.test(prompt))return 10;
    const explicit=prompt.match(/(?:représentant|secteurs? sur)\s*(\d+)(?:\s*parts?)?\s*sur\s*100/i);
    return explicit?Number(explicit[1]):null;
  }

  function questionTools(prompt){
    const match=String(prompt||'').match(/\[TOOLS\]([\s\S]*?)\[\/TOOLS\]/i);
    if(!match)return [];
    return match[1].split(',').map(tool=>tool.trim().toLowerCase())
      .filter(tool=>tool==='scratch'||tool==='calculator');
  }
  function parse(prompt){
    const normalized=String(prompt||'').replace(/\[TOOLS\][\s\S]*?\[\/TOOLS\]\s*/ig,'').replace(/^[◐◔◕●○]\s*(?:\([^)]*\))?\s*/,'');
    let match;

    if((match=normalized.match(/\[OPERATION\]([\s\S]*?)\[\/OPERATION\]/i))){
      return {text:normalized.replace(match[0],'').trim(),visual:createOperation(match[1])};
    }
    if((match=normalized.match(/\[TABLE\]([\s\S]*?)\[\/TABLE\]/i))){
      const rows=match[1].trim().split('\n').map(line=>line.split('|').map(value=>value.trim()));
      return {text:normalized.replace(match[0],'').trim(),visual:createTable(rows)};
    }
    if((match=normalized.match(/\[BARS\]([\s\S]*?)\[\/BARS\]/i))){
      const entries=match[1].split(';').map(pair=>{
        const separator=pair.lastIndexOf('=');
        return {label:pair.slice(0,separator).trim(),value:Number(pair.slice(separator+1))};
      }).filter(entry=>entry.label&&Number.isFinite(entry.value));
      if(entries.length)return {text:normalized.replace(match[0],'').trim(),visual:createNamedBars(entries)};
    }
    if((match=normalized.match(/\[PIE\]\s*(\d+(?:[.,]\d+)?)\s*\[\/PIE\]/i))){
      return {text:normalized.replace(match[0],'').trim(),visual:createPie(Number(match[1].replace(',','.')))};
    }
    if((match=normalized.match(/\[CURVE\]([\s\S]*?)\[\/CURVE\]/i))){
      const points=match[1].split(';').map(pair=>{
        const [hour,value]=pair.split('=').map(Number);
        return {hour,value};
      }).filter(point=>Number.isFinite(point.hour)&&Number.isFinite(point.value));
      if(points.length>=2)return {text:normalized.replace(match[0],'').trim(),visual:createCurve(points)};
    }

    if((match=normalized.match(/\[ANGLE\]\s*(\d+(?:[.,]\d+)?)\s*\[\/ANGLE\]/i))){
      return {text:normalized.replace(match[0],'').trim(),visual:createAngleDiagram(Number(match[1].replace(',','.')))};
    }
    if((match=normalized.match(/\[CODEDTRIANGLE\]\s*([a-z-]+)\s*\[\/CODEDTRIANGLE\]/i))){
      return {text:normalized.replace(match[0],'').trim(),visual:createCodedTriangle(match[1])};
    }
    if((match=normalized.match(/\[ANGLECROSS\]\s*(\d+(?:[.,]\d+)?)?\s*\[\/ANGLECROSS\]/i))){
      return {text:normalized.replace(match[0],'').trim(),visual:createCrossingAngles(match[1]?Number(match[1].replace(',','.')):null)};
    }
    if((match=normalized.match(/\[PARALLELANGLES\]\s*\[\/PARALLELANGLES\]/i))){
      return {text:normalized.replace(match[0],'').trim(),visual:createParallelAngles()};
    }
    if((match=normalized.match(/\[CUBEVIEW\]([\s\S]*?)\[\/CUBEVIEW\]/i))){
      const heights=match[1].split(',').map(Number);
      if(heights.length&&heights.every(value=>Number.isInteger(value)&&value>=0)){
        return {text:normalized.replace(match[0],'').trim(),visual:createCubeView(heights)};
      }
    }
    if((match=normalized.match(/\[TOPVIEW\]([\s\S]*?)\[\/TOPVIEW\]/i))){
      const rows=match[1].split(';').map(row=>row.split(',').map(Number));
      if(rows.length&&rows.every(row=>row.length&&row.every(value=>value===0||value===1))){
        return {text:normalized.replace(match[0],'').trim(),visual:createTopView(rows)};
      }
    }
    if((match=normalized.match(/\[CUBESTACK\]([\s\S]*?)\[\/CUBESTACK\]/i))){
      const heights=match[1].trim().split(';').map(row=>row.split(',').map(Number));
      if(heights.length&&heights.every(row=>row.length&&row.every(value=>Number.isInteger(value)&&value>=0))){
        return {text:normalized.replace(match[0],'').trim(),visual:createCubeStack(heights)};
      }
    }
    if((match=normalized.match(/\[SOLIDS\]([\s\S]*?)\[\/SOLIDS\]/i))){
      const entries=match[1].split(';').map(item=>{
        const parts=item.split('=');
        return parts.length===2?{label:parts[0].trim(),type:parts[1].trim().toLowerCase()}:null;
      }).filter(Boolean);
      if(entries.length)return {text:normalized.replace(match[0],'').trim(),visual:createSolidGallery(entries)};
    }
    if((match=normalized.match(/\[COORDINATES\]([\s\S]*?)\[\/COORDINATES\]/i))){
      const points=match[1].split(';').map(item=>{
        const pointMatch=item.trim().match(/^([^=]+)=(-?\d+(?:[.,]\d+)?),(-?\d+(?:[.,]\d+)?)$/);
        return pointMatch?{label:pointMatch[1].trim(),x:Number(pointMatch[2].replace(',','.')),y:Number(pointMatch[3].replace(',','.'))}:null;
      }).filter(Boolean);
      if(points.length)return {text:normalized.replace(match[0],'').trim(),visual:createCoordinatePlane(points)};
    }
    if((match=normalized.match(/Dans un tableau de proportionnalité\s*:\s*\n(\d+) objets → ([\d,]+) €\s*\n(\d+) objets → ([\d,]+) €\s*\n\s*([\s\S]*)/i))){
      return {text:match[5],visual:createTable([
        ['Quantité',match[1],match[3]],
        ['Prix (€)',match[2],match[4]]
      ])};
    }

    if((match=normalized.match(/A\s*\|\s*█+\s*(\d+)\s*\nB\s*\|\s*█+\s*(\d+)/))){
      const text=normalized.split('\n').filter(line=>!/^A\s*\||^B\s*\||diagramme en barres/i.test(line.trim())).join('\n').trim();
      return {text,visual:createBars(Number(match[1]),Number(match[2]))};
    }

    const pipeLines=normalized.split('\n').map(line=>line.trim()).filter(line=>line.includes('|'));
    if(pipeLines.length>=2){
      const rows=pipeLines.map(line=>line.split('|').map(value=>value.trim()));
      const text=normalized.split('\n').filter(line=>!line.includes('|')&&!/^(Lis|Complète|Observe) (ce |le )?tableau/i.test(line.trim())).join('\n').trim();
      return {text,visual:createTable(rows)};
    }

    const percent=piePercent(normalized);
    if(percent!==null&&/diagramme circulaire/i.test(normalized)){
      return {text:normalized,visual:createPie(percent)};
    }

    if((match=normalized.match(/\[DONNÉES_COURBE\]\s*([^\n]+)/i))){
      const points=match[1].split(';').map(pair=>{
        const [hour,value]=pair.split('=').map(Number);
        return {hour,value};
      }).filter(point=>Number.isFinite(point.hour)&&Number.isFinite(point.value));
      const text=normalized.split('\n')
        .filter(line=>!/\[DONNÉES_COURBE\]/i.test(line)&&!/^Observe (cette|la) courbe/i.test(line.trim()))
        .join('\n').trim();
      if(points.length>=2)return {text,visual:createCurve(points)};
    }

    if(/extrait de courbe/i.test(normalized)){
      const values=[...normalized.matchAll(/^(\d+)\s*┤/gm)].map(item=>Number(item[1]));
      const hours=[...normalized.matchAll(/(\d+)\s*h/g)].map(item=>Number(item[1]));
      if(values.length>=2&&hours.length>=2){
        const question=normalized.split('\n').find(line=>/Quelle valeur/i.test(line))||'';
        return {text:question,visual:createCurve([
          {hour:hours[0],value:values[1]},
          {hour:hours[1],value:values[0]}
        ])};
      }
    }
    return {text:normalized,visual:null};
  }

  function render(textElement,visualElement,prompt){
    const result=parse(prompt);
    if(window.CapCollegeEducationalContent){
      window.CapCollegeEducationalContent.renderInline(textElement,result.text);
    }else{
      textElement.textContent=result.text;
    }
    if(visualElement){
      visualElement.replaceChildren();
      visualElement.classList.toggle('hidden',!result.visual);
      if(result.visual)visualElement.appendChild(result.visual);
    }
  }

  function toolStorageKey(prompt){
    let hash=2166136261;
    const value=String(prompt||'');
    for(let index=0;index<value.length;index++){
      hash^=value.charCodeAt(index);
      hash=Math.imul(hash,16777619);
    }
    return 'cap-college-scratch:'+location.pathname+':'+(hash>>>0);
  }

  function createScratchTool(prompt){
    const details=document.createElement('details');
    details.className='question-tool-widget';
    const summary=document.createElement('summary');
    summary.className='question-tool-badge';
    summary.textContent='✏️ Ouvrir le brouillon';
    details.appendChild(summary);
    const panel=document.createElement('div');
    panel.className='question-tool-panel';
    const textarea=document.createElement('textarea');
    textarea.className='question-scratchpad';
    textarea.rows=7;
    textarea.placeholder='Écris ici tes calculs, tes étapes ou tes idées…';
    textarea.setAttribute('aria-label','Brouillon de la question');
    const storageKey=toolStorageKey(prompt);
    try{textarea.value=sessionStorage.getItem(storageKey)||'';}catch(error){}
    textarea.addEventListener('input',()=>{
      try{sessionStorage.setItem(storageKey,textarea.value);}catch(error){}
    });
    const clear=document.createElement('button');
    clear.type='button';
    clear.className='btn btn-secondary question-tool-clear';
    clear.textContent='Effacer le brouillon';
    clear.addEventListener('click',()=>{
      textarea.value='';
      try{sessionStorage.removeItem(storageKey);}catch(error){}
      textarea.focus();
    });
    panel.append(textarea,clear);
    details.appendChild(panel);
    return details;
  }

  function calculateExpression(source){
    const compact=String(source||'').replace(/\s+/g,'');
    const tokens=compact.match(/\d+(?:[.,]\d+)?|[()+\-*/]/g)||[];
    if(!compact||tokens.join('')!==compact)return null;
    let position=0;
    const expression=()=>{
      let value=term();
      while(tokens[position]==='+'||tokens[position]==='-'){
        const operator=tokens[position++];
        const next=term();
        value=operator==='+'?value+next:value-next;
      }
      return value;
    };
    const term=()=>{
      let value=factor();
      while(tokens[position]==='*'||tokens[position]==='/'){
        const operator=tokens[position++];
        const next=factor();
        value=operator==='*'?value*next:value/next;
      }
      return value;
    };
    const factor=()=>{
      const token=tokens[position++];
      if(token==='-')return -factor();
      if(token==='+')return factor();
      if(token==='('){
        const value=expression();
        if(tokens[position++]!==')')throw new Error('parenthèse');
        return value;
      }
      const value=Number(String(token).replace(',','.'));
      if(!Number.isFinite(value))throw new Error('nombre');
      return value;
    };
    try{
      const value=expression();
      return position===tokens.length&&Number.isFinite(value)?value:null;
    }catch(error){
      return null;
    }
  }

  function createCalculatorTool(){
    const details=document.createElement('details');
    details.className='question-tool-widget';
    const summary=document.createElement('summary');
    summary.className='question-tool-badge';
    summary.textContent='🧮 Ouvrir la calculatrice';
    details.appendChild(summary);
    const panel=document.createElement('div');
    panel.className='question-tool-panel question-calculator';
    const display=document.createElement('input');
    display.className='question-calculator-display';
    display.type='text';
    display.readOnly=true;
    display.inputMode='none';
    display.setAttribute('aria-label','Écran de la calculatrice');
    const keys=[
      ['C','clear'],['(','('],[')',')'],['←','backspace'],
      ['7','7'],['8','8'],['9','9'],['÷','/'],
      ['4','4'],['5','5'],['6','6'],['×','*'],
      ['1','1'],['2','2'],['3','3'],['−','-'],
      ['0','0'],[',',','],['=','equals'],['+','+']
    ];
    const grid=document.createElement('div');
    grid.className='question-calculator-grid';
    keys.forEach(([label,value])=>{
      const button=document.createElement('button');
      button.type='button';
      button.className='question-calculator-key';
      button.textContent=label;
      button.setAttribute('aria-label',label==='←'?'Effacer le dernier caractère':label);
      button.addEventListener('click',()=>{
        if(value==='clear'){display.value='';return;}
        if(value==='backspace'){display.value=display.value.slice(0,-1);return;}
        if(value==='equals'){
          const result=calculateExpression(display.value);
          display.value=result===null?'Erreur':String(Math.round((result+Number.EPSILON)*1e10)/1e10).replace('.',',');
          return;
        }
        if(display.value==='Erreur')display.value='';
        display.value+=value;
      });
      grid.appendChild(button);
    });
    panel.append(display,grid);
    details.appendChild(panel);
    return details;
  }

  function renderTools(container,prompt){
    if(!container)return;
    const tools=questionTools(prompt);
    container.replaceChildren();
    tools.forEach(tool=>{
      container.appendChild(tool==='scratch'?createScratchTool(prompt):createCalculatorTool());
    });
    container.classList.toggle('hidden',tools.length===0);
  }
  window.CapCollegeQuestionVisuals={render,parse,questionTools,renderTools};
})();
