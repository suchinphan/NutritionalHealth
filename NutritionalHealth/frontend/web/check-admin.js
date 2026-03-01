// Frontend admin guard: include on every admin page
(() => {
  try {
    const admin = JSON.parse(localStorage.getItem('admin') || sessionStorage.getItem('admin') || 'null');
    if (!admin || admin.is_admin !== 1) {
      // Not admin -> redirect to login
      window.location.href = 'admin_login.html';
    }
  } catch (e) {
    window.location.href = 'admin_login.html';
  }
})();
