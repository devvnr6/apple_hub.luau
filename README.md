# KeyVault - Digital Subscriptions & License Keys

A modern, responsive website for selling digital subscription/license products. Built with clean HTML5, CSS3, and vanilla JavaScript with TailwindCSS for styling.

## Features

- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- **Modern UI/UX**: Clean, minimal aesthetic with smooth animations
- **Smooth Scrolling**: Navigate between sections with smooth scroll behavior
- **Dynamic Content**: Products and reviews loaded from JSON data
- **Interactive Elements**: Hover effects, fade-in animations, and transitions
- **SEO Optimized**: Proper meta tags, semantic HTML, and accessibility features

## Sections

1. **Hero Section**: Eye-catching landing with call-to-action buttons
2. **Advantages**: Grid showcasing key benefits with icons
3. **How to Buy**: 3-step illustrated purchase process
4. **Products**: Subscription plans with pricing cards
5. **Payment Methods**: Supported payment options
6. **Reviews**: Customer testimonials
7. **Contact**: Support and contact information
8. **Footer**: Links and social media

## Technology Stack

- **HTML5**: Semantic markup
- **CSS3**: Custom styles with animations
- **TailwindCSS**: Utility-first CSS framework (via CDN)
- **JavaScript**: Vanilla JS for interactivity
- **Google Fonts**: Inter font family

## Installation & Setup

### Option 1: Simple HTTP Server (Recommended)

1. Clone or download the repository
2. Open terminal in the project directory
3. Run a simple HTTP server:

**Using Python 3:**
```bash
python3 -m http.server 8000
```

**Using Python 2:**
```bash
python -m SimpleHTTPServer 8000
```

**Using Node.js (http-server):**
```bash
npx http-server -p 8000
```

**Using PHP:**
```bash
php -S localhost:8000
```

4. Open your browser and navigate to `http://localhost:8000`

### Option 2: Open Directly in Browser

Simply open `index.html` in your web browser. Note: Some features may not work properly when opening files directly due to CORS restrictions.

## File Structure

```
.
├── index.html          # Main HTML file
├── styles.css          # Custom CSS styles and animations
├── script.js           # JavaScript for interactivity
├── data.json           # Products, advantages, and reviews data
└── README.md           # This file
```

## Customization

### Modifying Colors

Colors are defined in the TailwindCSS config in `index.html`:

```javascript
tailwind.config = {
    theme: {
        extend: {
            colors: {
                primary: '#6366f1',    // Indigo
                secondary: '#8b5cf6',  // Purple
                accent: '#ec4899',     // Pink
                dark: '#0f172a',       // Dark blue
                'dark-light': '#1e293b',
            }
        }
    }
}
```

### Modifying Content

#### Products
Edit `data.json` to add, remove, or modify subscription plans:

```json
{
  "id": "plan-id",
  "name": "Plan Name",
  "price": 29.99,
  "period": "month",
  "popular": true,
  "features": [
    "Feature 1",
    "Feature 2"
  ]
}
```

#### Advantages
Edit the `advantages` array in `data.json`:

```json
{
  "icon": "SVG_CODE_HERE",
  "title": "Advantage Title",
  "description": "Description text"
}
```

#### Reviews
Edit the `reviews` array in `data.json`:

```json
{
  "author": "Name",
  "rating": 5,
  "text": "Review text",
  "date": "Month Year"
}
```

### Modifying Styles

- **Custom styles**: Edit `styles.css`
- **Layout**: Modify TailwindCSS classes in `index.html`
- **Animations**: Adjust animation timings in `styles.css`

## JavaScript Functionality

The `script.js` file includes:

- **Navigation**: Sticky navbar with scroll effect
- **Mobile menu**: Responsive mobile navigation
- **Smooth scrolling**: Smooth navigation between sections
- **Animations**: Intersection Observer for fade-in effects
- **Dynamic content**: Loads data from `data.json`
- **Active link highlighting**: Highlights current section in nav
- **Purchase handler**: Placeholder for buy button functionality

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile browsers (iOS Safari, Chrome Mobile)

## Performance

- Lightweight: No heavy dependencies
- Fast loading: TailwindCSS loaded via CDN
- Optimized animations: CSS transitions and transforms
- Efficient JavaScript: Vanilla JS with minimal overhead

## Deployment

### Deploy to GitHub Pages

1. Push code to GitHub repository
2. Go to Settings > Pages
3. Select branch and root folder
4. Save and wait for deployment

### Deploy to Netlify

1. Drag and drop the project folder to Netlify
2. Or connect GitHub repository for automatic deployments

### Deploy to Vercel

```bash
npx vercel
```

## Future Enhancements

Potential features to add:

- [ ] Backend API integration
- [ ] Real payment gateway integration (Stripe, PayPal)
- [ ] User authentication
- [ ] Shopping cart functionality
- [ ] Email notifications
- [ ] Dark/Light mode toggle
- [ ] Multi-language support
- [ ] Admin dashboard
- [ ] Analytics integration

## License

This project is open source and available under the MIT License.

## Support

For questions or issues, please open an issue on the repository or contact support@keyvault.com

## Credits

- Icons: Heroicons (via inline SVG)
- Fonts: Inter by Google Fonts
- Framework: TailwindCSS

---

**Note**: This is a template/demo website. For production use, implement proper backend services, payment processing, and security measures.
