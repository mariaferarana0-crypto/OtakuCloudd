document.querySelectorAll('form[data-confirm]').forEach(form=>form.addEventListener('submit',e=>{if(!confirm(form.dataset.confirm))e.preventDefault()}));
const menu = document.querySelector('.mobile-menu');
const sidebar = document.querySelector('.side');
function closeMenu(){if(!sidebar||!menu)return;sidebar.classList.remove('open');menu.setAttribute('aria-expanded','false');}
if(menu&&sidebar){menu.addEventListener('click',()=>{const open=sidebar.classList.toggle('open');menu.setAttribute('aria-expanded',String(open));});document.addEventListener('click',e=>{if(!sidebar.contains(e.target)&&!menu.contains(e.target))closeMenu();});document.addEventListener('keydown',e=>{if(e.key==='Escape')closeMenu();});}
document.querySelectorAll('.password-toggle').forEach(btn=>btn.addEventListener('click',()=>{const field=btn.parentElement.querySelector('input');const show=field.type==='password';field.type=show?'text':'password';btn.textContent=show?'Ocultar':'Ver';btn.setAttribute('aria-label',show?'Ocultar contraseña':'Mostrar contraseña');}));
