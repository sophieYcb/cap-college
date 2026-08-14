(function(){
  const FRACTION_PATTERN=/(^|[^\p{L}\p{N}])([+-]?\d+|[a-zA-Z])\s*\/\s*([+-]?\d+|[a-zA-Z])(?![\p{L}\p{N}])/gu;

  function appendPlainText(target,text){
    String(text).split('\n').forEach((line,index)=>{
      if(index)target.appendChild(document.createElement('br'));
      target.appendChild(document.createTextNode(line));
    });
  }

  function appendFormatted(target,text){
    const source=String(text??'');
    let cursor=0;
    for(const match of source.matchAll(FRACTION_PATTERN)){
      const start=match.index;
      appendPlainText(target,source.slice(cursor,start)+match[1]);
      const fraction=document.createElement('span');
      fraction.className='math-fraction';
      fraction.setAttribute('role','math');
      fraction.setAttribute('aria-label',`${match[2]} sur ${match[3]}`);
      const numerator=document.createElement('span');
      numerator.className='math-fraction-numerator';
      numerator.textContent=match[2];
      const denominator=document.createElement('span');
      denominator.className='math-fraction-denominator';
      denominator.textContent=match[3];
      fraction.append(numerator,denominator);
      target.appendChild(fraction);
      cursor=start+match[0].length;
    }
    appendPlainText(target,source.slice(cursor));
  }

  function renderInline(element,text){
    element.replaceChildren();
    appendFormatted(element,text);
  }

  function toHtml(text){
    const wrapper=document.createElement('span');
    appendFormatted(wrapper,text);
    return wrapper.innerHTML;
  }

  window.CapCollegeEducationalContent={renderInline,toHtml};
})();
