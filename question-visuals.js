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
    rows.forEach((row,rowIndex)=>{
      const tr=document.createElement('tr');
      row.forEach((value,columnIndex)=>{
        const cell=document.createElement(rowIndex===0||columnIndex===0?'th':'td');
        cell.textContent=value;
        tr.appendChild(cell);
      });
      table.appendChild(tr);
    });
    wrapper.appendChild(table);
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
    const svg=svgNode('svg',{viewBox:'0 0 320 250',role:'img','aria-label':`Diagramme circulaire coloré à ${percent} %`});
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
    addSvgText(svg,`${percent} %`,cx,225,{class:'chart-value pie-value','text-anchor':'middle'});
    wrapper.appendChild(svg);
    return wrapper;
  }

  function createCurve(hour1,value1,hour2,value2){
    const wrapper=document.createElement('div');
    wrapper.className='question-visual';
    const svg=svgNode('svg',{viewBox:'0 0 540 280',role:'img','aria-label':`Courbe : ${value1} à ${hour1} h et ${value2} à ${hour2} h`});
    svg.classList.add('question-chart');
    const left=75,bottom=225,top=25,right=495;
    const min=Math.max(0,Math.min(value1,value2)-3);
    const max=Math.max(value1,value2)+3;
    const yFor=value=>bottom-((value-min)/(max-min))*(bottom-top);
    svg.appendChild(svgNode('line',{x1:left,y1:top,x2:left,y2:bottom,class:'chart-axis'}));
    svg.appendChild(svgNode('line',{x1:left,y1:bottom,x2:right,y2:bottom,class:'chart-axis'}));
    [min,value1,value2,max].filter((v,i,a)=>a.indexOf(v)===i).forEach(value=>{
      const y=yFor(value);
      svg.appendChild(svgNode('line',{x1:left,y1:y,x2:right,y2:y,class:'chart-grid'}));
      addSvgText(svg,value,left-12,y+5,{class:'chart-label','text-anchor':'end'});
    });
    const points=[[175,yFor(value1)],[400,yFor(value2)]];
    svg.appendChild(svgNode('polyline',{points:points.map(p=>p.join(',')).join(' '),class:'chart-line'}));
    points.forEach(([x,y],index)=>{
      svg.appendChild(svgNode('circle',{cx:x,cy:y,r:8,class:'chart-point'}));
      addSvgText(svg,index===0?`${hour1} h`:`${hour2} h`,x,bottom+30,{class:'chart-label chart-category','text-anchor':'middle'});
    });
    addSvgText(svg,'Valeur',18,20,{class:'chart-label chart-axis-title'});
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

    if(/extrait de courbe/i.test(normalized)){
      const values=[...normalized.matchAll(/^(\d+)\s*┤/gm)].map(item=>Number(item[1]));
      const hours=[...normalized.matchAll(/(\d+)\s*h/g)].map(item=>Number(item[1]));
      if(values.length>=2&&hours.length>=2){
        const question=normalized.split('\n').find(line=>/Quelle valeur/i.test(line))||'';
        return {text:question,visual:createCurve(hours[0],values[1],hours[1],values[0])};
      }
    }
    return {text:normalized,visual:null};
  }

  function render(textElement,visualElement,prompt){
    const result=parse(prompt);
    textElement.textContent=result.text;
    if(visualElement){
      visualElement.replaceChildren();
      visualElement.classList.toggle('hidden',!result.visual);
      if(result.visual)visualElement.appendChild(result.visual);
    }
  }

  window.CapCollegeQuestionVisuals={render,parse};
})();
