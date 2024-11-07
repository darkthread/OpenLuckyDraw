var list = JSON.parse(localStorage.getItem('runnerList') ?? '[]');
[...document.querySelectorAll('tr[onclick^=self]')].map((tr) => 
    list.push([...tr.querySelectorAll('td')].map(td => td.innerText).join(','))
);
console.log(list.length);
localStorage.setItem('runnerList', JSON.stringify(list));