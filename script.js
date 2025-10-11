// Navigation scroll effect
const navbar = document.getElementById('navbar');
const mobileMenuBtn = document.getElementById('mobile-menu-btn');
const mobileMenu = document.getElementById('mobile-menu');

window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
});

// Mobile menu toggle
mobileMenuBtn.addEventListener('click', () => {
    mobileMenu.classList.toggle('hidden');
});

// Close mobile menu when clicking a link
document.querySelectorAll('#mobile-menu a').forEach(link => {
    link.addEventListener('click', () => {
        mobileMenu.classList.add('hidden');
    });
});

// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            const offsetTop = target.offsetTop - 80; // Account for fixed navbar
            window.scrollTo({
                top: offsetTop,
                behavior: 'smooth'
            });
        }
    });
});

// Intersection Observer for fade-in animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry, index) => {
        if (entry.isIntersecting) {
            setTimeout(() => {
                entry.target.classList.add('visible');
            }, index * 100);
        }
    });
}, observerOptions);

// Observe all sections with fade-in class
document.querySelectorAll('.fade-in').forEach(el => {
    observer.observe(el);
});

// Load data from data.json
async function loadData() {
    try {
        const response = await fetch('data.json');
        const data = await response.json();
        
        // Load advantages
        loadAdvantages(data.advantages);
        
        // Load products
        loadProducts(data.products);
        
        // Load reviews
        loadReviews(data.reviews);
        
        // Observe newly created elements
        observeElements();
    } catch (error) {
        console.error('Error loading data:', error);
        // Fallback to hardcoded data if JSON fails
        loadFallbackData();
    }
}

function loadAdvantages(advantages) {
    const grid = document.getElementById('advantages-grid');
    grid.innerHTML = advantages.map((advantage, index) => `
        <div class="advantage-card animate-delay-${(index % 6) + 1}">
            <div class="advantage-icon">
                ${advantage.icon}
            </div>
            <h3>${advantage.title}</h3>
            <p>${advantage.description}</p>
        </div>
    `).join('');
}

function loadProducts(products) {
    const grid = document.getElementById('products-grid');
    grid.innerHTML = products.map((product, index) => `
        <div class="product-card ${product.popular ? 'popular' : ''} animate-delay-${(index % 4) + 1}">
            ${product.popular ? '<div class="product-badge">Popular</div>' : ''}
            <h3>${product.name}</h3>
            <div class="product-price">
                $${product.price}
                <span>/${product.period}</span>
            </div>
            <ul class="product-features">
                ${product.features.map(feature => `<li>${feature}</li>`).join('')}
            </ul>
            <button class="product-btn" onclick="buyProduct('${product.id}')">
                Buy Now
            </button>
        </div>
    `).join('');
}

function loadReviews(reviews) {
    const grid = document.getElementById('reviews-grid');
    grid.innerHTML = reviews.map((review, index) => `
        <div class="review-card animate-delay-${(index % 6) + 1}">
            <div class="review-stars">
                ${'★'.repeat(review.rating)}${'☆'.repeat(5 - review.rating)}
            </div>
            <p class="review-text">"${review.text}"</p>
            <div class="review-author">
                <div class="review-avatar">${review.author.charAt(0).toUpperCase()}</div>
                <div class="review-info">
                    <h4>${review.author}</h4>
                    <p>${review.date}</p>
                </div>
            </div>
        </div>
    `).join('');
}

function observeElements() {
    // Observe advantage cards
    document.querySelectorAll('.advantage-card').forEach(el => {
        observer.observe(el);
    });
    
    // Observe step cards
    document.querySelectorAll('.step-card').forEach(el => {
        observer.observe(el);
    });
    
    // Observe product cards
    document.querySelectorAll('.product-card').forEach(el => {
        observer.observe(el);
    });
    
    // Observe review cards
    document.querySelectorAll('.review-card').forEach(el => {
        observer.observe(el);
    });
}

function buyProduct(productId) {
    // This is a placeholder for the purchase functionality
    alert(`Initiating purchase for product: ${productId}\n\nIn a production environment, this would redirect to a payment gateway or open a checkout modal.`);
    
    // In a real implementation, this would:
    // 1. Add item to cart
    // 2. Redirect to checkout page
    // 3. Or open a payment modal
    // Example: window.location.href = `/checkout?product=${productId}`;
}

// Fallback data if JSON file is not available
function loadFallbackData() {
    const fallbackData = {
        advantages: [
            {
                icon: '<svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path></svg>',
                title: 'Complete Anonymity',
                description: 'No personal information required. Your privacy is our priority.'
            },
            {
                icon: '<svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>',
                title: 'Instant Delivery',
                description: 'Receive your license keys immediately after payment confirmation.'
            },
            {
                icon: '<svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>',
                title: 'Secure Payment',
                description: 'Multiple secure payment methods including crypto and credit cards.'
            },
            {
                icon: '<svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
                title: '24/7 Support',
                description: 'Round-the-clock customer support via Telegram and email.'
            },
            {
                icon: '<svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path></svg>',
                title: 'Best Prices',
                description: 'Competitive pricing with regular discounts and special offers.'
            },
            {
                icon: '<svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>',
                title: 'Verified Products',
                description: 'All keys are tested and verified to ensure they work perfectly.'
            }
        ],
        products: [
            {
                id: 'trial-7',
                name: '7-Day Trial',
                price: 9.99,
                period: '7 days',
                popular: false,
                features: [
                    'Full access to all features',
                    'Premium support',
                    'Instant activation',
                    'Money-back guarantee'
                ]
            },
            {
                id: 'monthly-30',
                name: 'Monthly Plan',
                price: 29.99,
                period: 'month',
                popular: true,
                features: [
                    'Full access to all features',
                    'Priority support',
                    'Instant activation',
                    'Auto-renewal option',
                    'Money-back guarantee'
                ]
            },
            {
                id: 'quarterly-90',
                name: 'Quarterly Plan',
                price: 79.99,
                period: '3 months',
                popular: false,
                features: [
                    'Full access to all features',
                    'Priority support',
                    'Instant activation',
                    'Save 15%',
                    'Money-back guarantee'
                ]
            },
            {
                id: 'yearly-365',
                name: 'Yearly Plan',
                price: 249.99,
                period: 'year',
                popular: false,
                features: [
                    'Full access to all features',
                    'VIP support',
                    'Instant activation',
                    'Save 30%',
                    'Lifetime updates',
                    'Money-back guarantee'
                ]
            }
        ],
        reviews: [
            {
                author: 'Alex Johnson',
                rating: 5,
                text: 'Fast delivery and excellent service! Got my key within minutes. Highly recommended!',
                date: 'March 2025'
            },
            {
                author: 'Sarah Mitchell',
                rating: 5,
                text: 'Best prices I could find anywhere. The process was smooth and support is very helpful.',
                date: 'February 2025'
            },
            {
                author: 'Mike Chen',
                rating: 5,
                text: 'Been using their service for months now. Never had any issues. Great reliability!',
                date: 'January 2025'
            },
            {
                author: 'Emma Davis',
                rating: 4,
                text: 'Good service overall. The key worked perfectly and the price was fair.',
                date: 'March 2025'
            },
            {
                author: 'Chris Taylor',
                rating: 5,
                text: 'Anonymous payment was a huge plus for me. Everything worked as described.',
                date: 'February 2025'
            },
            {
                author: 'Lisa Anderson',
                rating: 5,
                text: 'Instant delivery is no joke! Got my license in under 2 minutes. Amazing service!',
                date: 'March 2025'
            }
        ]
    };
    
    loadAdvantages(fallbackData.advantages);
    loadProducts(fallbackData.products);
    loadReviews(fallbackData.reviews);
    observeElements();
}

// Load data when page is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadData);
} else {
    loadData();
}

// Active nav link highlight
const sections = document.querySelectorAll('section[id]');
const navLinks = document.querySelectorAll('.nav-link');

window.addEventListener('scroll', () => {
    let current = '';
    
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        if (window.pageYOffset >= sectionTop - 100) {
            current = section.getAttribute('id');
        }
    });
    
    navLinks.forEach(link => {
        link.classList.remove('text-primary');
        if (link.getAttribute('href') === `#${current}`) {
            link.classList.add('text-primary');
        }
    });
});
