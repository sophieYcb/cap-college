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

  function createCoordinatePlane(points){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const description=points.map(point=>point.label+'('+point.x+' ; '+point.y+')').join(', ');
    const svg=svgNode('svg',{viewBox:'0 0 540 340',role:'img','aria-label':'Repère contenant les points '+description});
    svg.classList.add('question-chart');
    const left=70,right=500,top=25,bottom=295;
    const xValues=points.map(point=>point.x),yValues=points.map(point=>point.y);
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

  function parse(prompt){
    const normalized=String(prompt||'').replace(/^[◐◔◕●○]\s*(?:\([^)]*\))?\s*/,'');
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

  window.CapCollegeQuestionVisuals={render,parse};
})();
