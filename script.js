// Nav toggle on mobile
const navToggle = document.getElementById('navToggle');
const navLinks = document.querySelector('.nav-links');
const navActions = document.querySelector('.nav-actions');

navToggle.addEventListener('click', () => {
  navLinks.classList.toggle('active');
  navActions.classList.toggle('active');
});

// Close mobile menu when clicking a link
document.querySelectorAll('.nav-links a').forEach((link) => {
  link.addEventListener('click', () => {
    navLinks.classList.remove('active');
    navActions.classList.remove('active');
  });
});

// Navbar scroll effect
const navbar = document.getElementById('navbar');
let lastScroll = 0;

window.addEventListener('scroll', () => {
  const currentScroll = window.scrollY;

  if (currentScroll > 50) {
    navbar.style.boxShadow = '0 4px 30px rgba(0, 0, 0, 0.4)';
  } else {
    navbar.style.boxShadow = 'none';
  }

  lastScroll = currentScroll;
});

// Copy to clipboard
const copyBtn = document.getElementById('copyBtn');
const copyFeedback = document.getElementById('copyFeedback');

copyBtn.addEventListener('click', () => {
  const text = 'gem install dto-cli';

  if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(() => {
      showCopyFeedback();
    });
  } else {
    // Fallback
    const textarea = document.createElement('textarea');
    textarea.value = text;
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
    showCopyFeedback();
  }
});

function showCopyFeedback() {
  copyFeedback.classList.add('visible');
  setTimeout(() => {
    copyFeedback.classList.remove('visible');
  }, 2000);
}

// Scroll reveal animation
const observerOptions = {
  threshold: 0.1,
  rootMargin: '0px 0px -50px 0px',
};

const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = '1';
      entry.target.style.transform = 'translateY(0)';
      observer.unobserve(entry.target);
    }
  });
}, observerOptions);

document.querySelectorAll('.feature-card, .step, .pricing-card').forEach((el) => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(20px)';
  el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
  observer.observe(el);
});
