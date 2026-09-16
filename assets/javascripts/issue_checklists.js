(function () {
  document.addEventListener('change', function (event) {
    var checkbox = event.target;
    if (!checkbox.classList || !checkbox.classList.contains('issue-checklist-toggle')) {
      return;
    }
    var form = checkbox.form || checkbox.closest('form');
    if (form) {
      form.submit();
    }
  });
})();
