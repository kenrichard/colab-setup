// Every `.command` block on a page: the Copy button copies the <code> beside it.
document.querySelectorAll('.command').forEach((block) => {
  const code = block.querySelector('code');
  const button = block.querySelector('button.copy');
  button.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(code.textContent);
    } catch {
      // Older browsers: select the text so ⌘C copies it.
      const range = document.createRange();
      range.selectNodeContents(code);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      button.textContent = 'Press ⌘C';
      return;
    }
    button.textContent = 'Copied';
    button.classList.add('copied');
    setTimeout(() => { button.textContent = 'Copy'; button.classList.remove('copied'); }, 2000);
  });
});
