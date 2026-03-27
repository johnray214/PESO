<template>
  <div class="landing" ref="landing">

    <!-- NAV -->
    <nav class="nav" :class="{ 'nav-scrolled': scrolled }">
      <div class="nav-inner">
        <div class="nav-logo">
          <div class="logo-mark">
            <img :src="pesoLogo" alt="PESO" class="logo-img" />
          </div>
          <div>
            <span class="logo-name">PESO</span>
            <span class="logo-tag">Employer Portal</span>
          </div>
        </div>
        <div class="nav-links">
          <button type="button" class="nav-link" :class="{ active: activeSection === 'features' }" @click="scrollTo('features')">Features</button>
          <button type="button" class="nav-link" :class="{ active: activeSection === 'how'      }" @click="scrollTo('how')">How It Works</button>
          <button type="button" class="nav-link" :class="{ active: activeSection === 'benefits' }" @click="scrollTo('benefits')">Benefits</button>
        </div>
        <div class="nav-actions">
          <router-link to="/employer/login" class="btn-outline-nav">Log In</router-link>
          <router-link to="/employer/register" class="btn-primary-nav ripple-btn" @click="ripple">Register</router-link>
        </div>
      </div>
    </nav>

    <!-- HERO -->
    <section class="hero" id="hero">
      <div class="hero-bg">
        <div class="hero-orb orb1"></div>
        <div class="hero-orb orb2"></div>
        <div class="hero-grid"></div>
      </div>
      <div class="hero-inner">
        <div class="hero-text reveal" :class="{ visible: heroVisible }">
          <div class="hero-badge slide-in-badge">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            Official PESO Employer Platform
          </div>
          <h1 class="hero-title">Find the <span class="hero-accent">Right Talent</span><br/>for Your Business</h1>
          <p class="hero-sub">Connect with job-ready applicants from the Public Employment Service Office. Post jobs, review applicants, and hire with confidence — all in one place.</p>
          <div class="hero-cta">
            <router-link to="/employer/register" class="cta-primary ripple-btn">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
              Get Started for Free
            </router-link>
            <a href="#how" class="cta-ghost" @click.prevent="scrollTo('how')">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polygon points="10 8 16 12 10 16 10 8"/></svg>
              See How It Works
            </a>
          </div>
          <div class="hero-stats">
            <div class="hstat" v-for="(s, i) in heroStats" :key="s.label" :style="{ animationDelay: (0.6 + i * 0.12) + 's' }">
              <span class="hstat-val">{{ heroVisible ? s.val : '0' }}</span>
              <span class="hstat-label">{{ s.label }}</span>
            </div>
          </div>
        </div>
        <div class="hero-visual reveal-right" :class="{ visible: heroVisible }">
          <div class="preview-card">
            <div class="preview-topbar">
              <div class="preview-dots">
                <span></span><span></span><span></span>
              </div>
              <span class="preview-url">peso.gov.ph/employer</span>
            </div>
            <div class="preview-body">
              <div class="preview-sidebar">
                <div class="ps-logo"></div>
                <div class="ps-item active"></div>
                <div class="ps-item"></div>
                <div class="ps-item"></div>
                <div class="ps-item"></div>
              </div>
              <div class="preview-main">
                <div class="preview-stats-row">
                  <div class="pstat blue"><span class="pstat-num">142</span><span class="pstat-lbl">Applicants</span></div>
                  <div class="pstat sky"><span class="pstat-num">7</span><span class="pstat-lbl">Jobs Open</span></div>
                  <div class="pstat green"><span class="pstat-num">12</span><span class="pstat-lbl">Hired</span></div>
                </div>
                <div class="preview-chart">
                  <div class="pc-label">Applications This Month</div>
                  <div class="pc-bars">
                    <div v-for="b in chartBars" :key="b.h" class="pc-bar" :style="{ height: b.h + 'px', background: b.c }"></div>
                  </div>
                </div>
                <div class="preview-list-label">Recent Applicants</div>
                <div class="preview-list">
                  <div v-for="a in previewApps" :key="a.name" class="plist-row">
                    <div class="plist-avatar" :style="{ background: a.color }">{{ a.init }}</div>
                    <div class="plist-info">
                      <div class="plist-name">{{ a.name }}</div>
                      <div class="plist-role">{{ a.role }}</div>
                    </div>
                    <div class="plist-match" :style="{ color: a.match >= 85 ? '#22c55e' : '#2872A1' }">{{ a.match }}%</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="float-badge fb1">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
            <span>New applicant matched!</span>
          </div>
          <div class="float-badge fb2">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>
            <span>3 new applications today</span>
          </div>
        </div>
      </div>
    </section>

    <!-- TRUST BAR -->
    <section class="trust-bar reveal-up" :class="{ visible: trustVisible }" ref="trustRef">
      <p class="trust-label">Trusted by employers across the Philippines</p>
      <div class="trust-logos">
        <div v-for="(t, i) in trustLogos" :key="t" class="trust-logo-pill" :style="{ animationDelay: i * 0.07 + 's' }">{{ t }}</div>
      </div>
    </section>

    <!-- FEATURES -->
    <section class="section">
      <div class="section-inner" id="features" ref="featuresRef">
        <div class="section-header reveal-up" :class="{ visible: featuresVisible }">
          <div class="section-badge">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>
            Platform Features
          </div>
          <h2 class="section-title">Everything you need to<br/><span class="accent">hire smarter</span></h2>
          <p class="section-sub">PESO gives you the tools to attract, evaluate, and hire the best talent — faster than ever before.</p>
        </div>
        <div class="features-grid">
          <div
            v-for="(f, i) in features" :key="f.title"
            class="feature-card stagger-card"
            :class="{ visible: featuresVisible }"
            :style="{ animationDelay: (i * 0.09) + 's' }"
          >
            <div class="feature-icon-wrap" :style="{ background: f.bg }">
              <span v-html="f.icon" :style="{ color: f.color }"></span>
            </div>
            <h3 class="feature-title">{{ f.title }}</h3>
            <p class="feature-desc">{{ f.desc }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- HOW IT WORKS -->
    <section class="section section-alt">
      <div class="section-inner" id="how" ref="howRef">
        <div class="section-header reveal-up" :class="{ visible: howVisible }">
          <div class="section-badge">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
            Simple Process
          </div>
          <h2 class="section-title">Start hiring in<br/><span class="accent">3 easy steps</span></h2>
        </div>
        <div class="steps-row">
          <div
            v-for="(step, i) in steps" :key="step.title"
            class="step-card stagger-card"
            :class="{ visible: howVisible }"
            :style="{ animationDelay: (i * 0.15) + 's' }"
          >
            <div class="step-num">{{ String(i+1).padStart(2,'0') }}</div>
            <div class="step-icon-wrap" :style="{ background: step.bg }">
              <span v-html="step.icon" :style="{ color: step.color }"></span>
            </div>
            <h3 class="step-title">{{ step.title }}</h3>
            <p class="step-desc">{{ step.desc }}</p>
            <div v-if="i < steps.length - 1" class="step-arrow">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="2"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- SPLIT SECTION 1 -->
    <section class="section" ref="splitRef">
      <div class="section-inner">
        <div class="split-layout">
          <div class="split-text reveal" :class="{ visible: splitVisible }">
            <div class="section-badge">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
              Smart Matching
            </div>
            <h2 class="section-title" style="text-align:left">Match applicants to<br/><span class="accent">your job requirements</span></h2>
            <p class="section-sub" style="text-align:left">Our matching system scores every applicant against your job posting — skills, experience, location, and more. Focus your time on candidates who actually fit.</p>
            <ul class="check-list">
              <li v-for="(c, i) in checkList" :key="c" class="check-item" :style="{ animationDelay: splitVisible ? (i * 0.08 + 0.3) + 's' : '0s' }">
                <span class="check-icon">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
                </span>
                {{ c }}
              </li>
            </ul>
          </div>
          <div class="split-image-wrap reveal-right" :class="{ visible: splitVisible }">
            <img :src="matchPic" alt="Applicant matching feature" class="match-img" />
          </div>
        </div>
      </div>
    </section>

    <!-- BENEFITS -->
    <section class="section section-dark">
      <div class="section-inner" id="benefits" ref="benefitsRef">
        <div class="section-header reveal-up" :class="{ visible: benefitsVisible }">
          <div class="section-badge dark-badge">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#08BDDE" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            Why PESO
          </div>
          <h2 class="section-title light-title">Why employers choose<br/><span class="sky-accent">PESO Portal</span></h2>
        </div>
        <div class="benefits-grid">
          <div
            v-for="(b, i) in benefits" :key="b.title"
            class="benefit-card stagger-card"
            :class="{ visible: benefitsVisible }"
            :style="{ animationDelay: (i * 0.1) + 's' }"
          >
            <div class="benefit-icon">
              <span v-html="b.icon"></span>
            </div>
            <h3 class="benefit-title">{{ b.title }}</h3>
            <p class="benefit-desc">{{ b.desc }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- SPLIT SECTION 2 -->
    <section class="section" ref="split2Ref">
      <div class="section-inner">
        <div class="split-layout reverse">
          <div class="split-image-wrap reveal" :class="{ visible: split2Visible }">
            <div class="carousel-wrap">
              <img
                v-for="(img, i) in carouselImages"
                :key="i"
                :src="img"
                :class="['carousel-img', { active: carouselIndex === i }]"
                alt="Local hiring platform"
              />

              <!-- Arrows -->
              <button class="carousel-arrow left" @click="prevSlide">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="15 18 9 12 15 6"/></svg>
              </button>
              <button class="carousel-arrow right" @click="nextSlide">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="9 6 15 12 9 18"/></svg>
              </button>

              <!-- Dots -->
              <div class="carousel-dots">
                <button
                  v-for="(img, i) in carouselImages"
                  :key="i"
                  :class="['carousel-dot', { active: carouselIndex === i }]"
                  @click="goToSlide(i)"
                ></button>
              </div>
            </div>
          </div>
          <div class="split-text reveal-right" :class="{ visible: split2Visible }">
            <div class="section-badge">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>
              For Your Team
            </div>
            <h2 class="section-title" style="text-align:left">A hiring platform built<br/><span class="accent">for local businesses</span></h2>
            <p class="section-sub" style="text-align:left">Whether you're a small shop or a growing company, PESO connects you with local talent who are ready to work and live in your community.</p>
            <router-link to="/employer/register" class="cta-primary ripple-btn" style="display:inline-flex; margin-top:8px">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
              Create Employer Account
            </router-link>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA BANNER -->
    <section class="cta-section" ref="ctaRef">
      <div class="cta-inner">
        <div class="cta-orb c1"></div>
        <div class="cta-orb c2"></div>
        <div class="cta-content reveal-up" :class="{ visible: ctaVisible }">
          <h2 class="cta-title">Ready to find your next great hire?</h2>
          <p class="cta-sub">Join hundreds of employers already using PESO to connect with quality talent across the Philippines.</p>
          <div class="cta-buttons">
            <router-link to="/employer/login" class="cta-primary white ripple-btn">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
              Get Started for Free
            </router-link>
            <router-link to="/employer/login" class="cta-ghost-white">Already have an account? Log in</router-link>
          </div>
        </div>
      </div>
    </section>

    <!-- FOOTER -->
    <footer class="footer">
      <div class="footer-inner">
        <div class="footer-brand">
          <div class="footer-logo">
            <div class="logo-mark sm">
              <img :src="pesoLogo" alt="PESO" class="logo-img" />
            </div>
            <div>
              <span class="logo-name sm">PESO</span>
              <span class="logo-tag sm">Employer Portal</span>
            </div>
          </div>
          <p class="footer-tagline">Connecting employers with<br/>job-ready talent across the Philippines.</p>
        </div>
        <div class="footer-links-group">
          <p class="footer-group-title">Platform</p>
          <a class="footer-link" href="#features" @click.prevent="scrollTo('features')">Features</a>
          <a class="footer-link" href="#how"      @click.prevent="scrollTo('how')">How It Works</a>
          <a class="footer-link" href="#benefits" @click.prevent="scrollTo('benefits')">Benefits</a>
        </div>
        <div class="footer-links-group">
          <p class="footer-group-title">Account</p>
          <router-link class="footer-link" to="/employer/register">Get Started</router-link>
          <router-link class="footer-link" to="/employer/login">Login</router-link>
        </div>
        <div class="footer-links-group">
          <p class="footer-group-title">Government</p>
          <a class="footer-link" href="#">PESO Official</a>
          <a class="footer-link" href="#">DOLE Philippines</a>
          <a class="footer-link" href="#">PhilJobNet</a>
        </div>
      </div>
      <div class="footer-bottom">
        <p>© {{ new Date().getFullYear() }} Public Employment Service Office. All rights reserved.</p>
        <div class="footer-bottom-links">
          <a href="#">Privacy Policy</a>
          <a href="#">Terms of Service</a>
        </div>
      </div>
    </footer>

    <!-- Scroll to top button -->
    <button class="scroll-top-btn" :class="{ visible: scrolled }" @click="scrollToTop" title="Back to top">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="18 15 12 9 6 15"/></svg>
    </button>

  </div>
</template>

<script>
import pesoLogo from '@/assets/PESOLOGO.jpg'
import matchPic from '@/assets/matchpic.png'     
import carousel1 from '@/assets/carousel1.png'
import carousel2 from '@/assets/carousel2.png'
import carousel3 from '@/assets/carousel3.png'

export default {
  name: 'EmployerLanding',
  data() {
    return {
      pesoLogo,
      scrolled: false,
      activeSection: '',
      heroVisible:     false,
      trustVisible:    false,
      featuresVisible: false,
      howVisible:      false,
      splitVisible:    false,
      benefitsVisible: false,
      split2Visible:   false,
      ctaVisible:      false,

      matchPic,
      carouselImages: [carousel1, carousel2, carousel3],
      carouselIndex: 0,
      carouselTimer: null,

      heroStats: [
        { val: '5,000+', label: 'Active Jobseekers' },
        { val: '300+',   label: 'Employers' },
        { val: '1,200+', label: 'Hires Made' },
      ],
      chartBars: [
        { h: 28, c: '#bae6fd' }, { h: 40, c: '#7dd3fc' }, { h: 32, c: '#bae6fd' },
        { h: 52, c: '#2872A1' }, { h: 44, c: '#7dd3fc' }, { h: 60, c: '#2872A1' },
        { h: 48, c: '#08BDDE' },
      ],
      previewApps: [
        { init: 'C', name: 'Carlo Reyes',  role: 'Frontend Dev',   match: 94, color: '#2872A1' },
        { init: 'A', name: 'Ana Santos',   role: 'UI/UX Designer', match: 88, color: '#08BDDE' },
        { init: 'M', name: 'Mark Cruz',    role: 'Backend Dev',    match: 76, color: '#8b5cf6' },
      ],
      trustLogos: ['SM Retail', 'Jollibee', 'BDO Unibank', 'Globe Telecom', 'PLDT', "Robinson's"],
      features: [
        { title: 'Post Job Listings',        desc: 'Create detailed job postings in minutes. Set requirements, salary range, work type, and let PESO match you with qualified candidates.',          bg: '#eff8ff', color: '#2872A1', icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>` },
        { title: 'Smart Applicant Matching', desc: 'Our system automatically scores and ranks applicants based on how well they match your job requirements — saving you hours of manual screening.',   bg: '#f0f9ff', color: '#08BDDE', icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>` },
        { title: 'Applicant Profiles',       desc: 'View complete jobseeker profiles including work history, skills, certifications, and uploaded documents — all in one organized view.',              bg: '#faf5ff', color: '#8b5cf6', icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>` },
        { title: 'Interview Management',     desc: 'Organize your pipeline from application to hire. Move candidates through stages, schedule interviews, and track your hiring progress.',               bg: '#f0fdf4', color: '#22c55e', icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>` },
        { title: 'Notify Applicants',        desc: 'Send updates, interview invites, and status notifications to applicants directly from the platform. Keep everyone informed and engaged.',           bg: '#fffbeb', color: '#f59e0b', icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>` },
        { title: 'Hiring Analytics',         desc: 'Track applications over time, monitor your hiring funnel, and measure performance metrics to improve your recruitment strategy.',                    bg: '#fef2f2', color: '#ef4444', icon: `<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>` },
      ],
      steps: [
        { title: 'Register Your Company',   desc: 'Create your free employer account. Fill in your company profile, verify your details, and get approved by PESO.',                                  bg: '#eff8ff', color: '#2872A1', icon: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>` },
        { title: 'Post Your Job Openings',  desc: 'Create job listings with your requirements. Our system immediately starts matching qualified applicants from the PESO database.',                    bg: '#f0f9ff', color: '#08BDDE', icon: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/></svg>` },
        { title: 'Hire the Best Fit',       desc: 'Review matched applicants, manage your pipeline, conduct interviews, and hire — all from your employer dashboard.',                                 bg: '#f0fdf4', color: '#22c55e', icon: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>` },
      ],
      checkList: [
        'Automatic skill-based scoring',
        'Location and availability matching',
        'Experience level filtering',
        'Instant shortlist recommendations',
        'Side-by-side applicant comparison',
      ],
      benefits: [
        { title: 'Free to Use',         desc: 'No subscription fees or hidden charges. PESO employer accounts are completely free — because connecting people to work is a public service.',    icon: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#08BDDE" stroke-width="2"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>` },
        { title: 'Government-Backed',   desc: 'PESO is a government-run employment service. All applicants are registered, verified, and actively seeking work — no fake profiles.',           icon: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#08BDDE" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>` },
        { title: 'Local Talent Pool',   desc: 'Access applicants from your area — people who live nearby, know the community, and are ready to start work without relocation concerns.',       icon: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#08BDDE" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>` },
        { title: 'Fast Turnaround',     desc: 'Start receiving matched applicants within hours of posting. No waiting — your listing goes live immediately and matching runs automatically.',   icon: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#08BDDE" stroke-width="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>` },
      ],
    }
  },

  mounted() {
    // Hero animates immediately
    this.$nextTick(() => {
      setTimeout(() => { this.heroVisible = true }, 100)
    })

    // Scroll listener
    window.addEventListener('scroll', this.onScroll, { passive: true })

    // IntersectionObserver for sections
    const obs = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (!e.isIntersecting) return
        const key = e.target.dataset.obs
        if (key) this[key] = true
        obs.unobserve(e.target)
      })
    }, { threshold: 0.12 })

    const map = {
      trustRef:    'trustVisible',
      featuresRef: 'featuresVisible',
      howRef:      'howVisible',
      splitRef:    'splitVisible',
      benefitsRef: 'benefitsVisible',
      split2Ref:   'split2Visible',
      ctaRef:      'ctaVisible',
    }
    Object.entries(map).forEach(([ref, key]) => {
      if (this.$refs[ref]) {
        this.$refs[ref].dataset.obs = key
        obs.observe(this.$refs[ref])
      }
    })

    this.carouselTimer = setInterval(() => {
      this.carouselIndex = (this.carouselIndex + 1) % this.carouselImages.length
    }, 3000)
  },

  beforeUnmount() {
    window.removeEventListener('scroll', this.onScroll)
    clearInterval(this.carouselTimer)
  },

  methods: {

    prevSlide() {
      this.carouselIndex = (this.carouselIndex - 1 + this.carouselImages.length) % this.carouselImages.length
    },
    nextSlide() {
      this.carouselIndex = (this.carouselIndex + 1) % this.carouselImages.length
    },
    goToSlide(i) {
      this.carouselIndex = i
    },

    onScroll() {
      this.scrolled = window.scrollY > 40

      // Active section detection
      const sections = ['features', 'how', 'benefits']
      for (const id of sections) {
        const el = document.getElementById(id)
        if (!el) continue
        const rect = el.getBoundingClientRect()
        if (rect.top <= 100 && rect.bottom >= 100) {
          this.activeSection = id
          return
        }
      }
      this.activeSection = ''
    },

    scrollTo(id) {
      const el = document.getElementById(id)
      if (!el) return
      const offset = 72
      const top = el.getBoundingClientRect().top + window.scrollY - offset
      window.scrollTo({ top, behavior: 'smooth' })
    },

    scrollToTop() {
      window.scrollTo({ top: 0, behavior: 'smooth' })
    },

    ripple(e) {
      const btn = e.currentTarget
      const circle = document.createElement('span')
      const diameter = Math.max(btn.clientWidth, btn.clientHeight)
      const radius = diameter / 2
      const rect = btn.getBoundingClientRect()
      circle.style.cssText = `
        width:${diameter}px; height:${diameter}px;
        left:${e.clientX - rect.left - radius}px;
        top:${e.clientY - rect.top - radius}px;
        position:absolute; border-radius:50%;
        background:rgba(255,255,255,0.35);
        transform:scale(0); animation:ripple-anim 0.55s linear;
        pointer-events:none;
      `
      btn.style.position = 'relative'
      btn.style.overflow = 'hidden'
      btn.appendChild(circle)
      setTimeout(() => circle.remove(), 600)
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }
.landing { font-family: 'Plus Jakarta Sans', sans-serif; color: #1e293b; background: #fff; overflow-x: hidden; }

/* ── SCROLL ANIMATIONS ── */
.reveal {
  opacity: 0;
  transform: translateX(-32px);
  transition: opacity 0.65s cubic-bezier(.22,.68,0,1.2), transform 0.65s cubic-bezier(.22,.68,0,1.2);
}
.reveal.visible { opacity: 1; transform: translateX(0); }

.reveal-right {
  opacity: 0;
  transform: translateX(32px);
  transition: opacity 0.65s cubic-bezier(.22,.68,0,1.2), transform 0.65s cubic-bezier(.22,.68,0,1.2);
}
.reveal-right.visible { opacity: 1; transform: translateX(0); }

.reveal-up {
  opacity: 0;
  transform: translateY(28px);
  transition: opacity 0.6s cubic-bezier(.22,.68,0,1.2), transform 0.6s cubic-bezier(.22,.68,0,1.2);
}
.reveal-up.visible { opacity: 1; transform: translateY(0); }

.stagger-card {
  opacity: 0;
  transform: translateY(24px);
  transition: opacity 0.5s ease, transform 0.5s ease;
}
.stagger-card.visible { opacity: 1; transform: translateY(0); }

/* check items stagger */
.check-item {
  opacity: 0;
  transform: translateX(-16px);
  transition: opacity 0.4s ease, transform 0.4s ease;
}
.reveal.visible .check-item { opacity: 1; transform: translateX(0); }

/* hero slide-in badge */
.slide-in-badge {
  animation: badgeSlide 0.6s cubic-bezier(.22,.68,0,1.2) 0.2s both;
}
@keyframes badgeSlide {
  from { opacity: 0; transform: translateY(-12px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* hero text/visual — fire on heroVisible */
.hero-text.reveal   { transition-delay: 0.05s; }
.hero-visual.reveal-right { transition-delay: 0.2s; }

/* float badges pulse */
.float-badge {
  animation: floatBob 3.2s ease-in-out infinite;
}
.fb1 { animation-delay: 0s; }
.fb2 { animation-delay: 1.6s; }
@keyframes floatBob {
  0%, 100% { transform: translateY(0); }
  50%       { transform: translateY(-6px); }
}

/* trust pills stagger */
.trust-logo-pill {
  opacity: 0;
  transform: translateY(12px);
  transition: opacity 0.4s ease, transform 0.4s ease;
}
.reveal-up.visible .trust-logo-pill { opacity: 1; transform: translateY(0); }

/* pc bars grow animation */
.pc-bar {
  transform-origin: bottom;
  animation: barGrow 0.8s cubic-bezier(.22,.68,0,1.2) both;
}
@keyframes barGrow {
  from { transform: scaleY(0); }
  to   { transform: scaleY(1); }
}

/* ripple keyframe (global because it's injected) */
@keyframes ripple-anim {
  to { transform: scale(4); opacity: 0; }
}

/* ── NAV ── */
.nav {
  position: fixed; top: 0; left: 0; right: 0; z-index: 100;
  background: rgba(255,255,255,0.92); backdrop-filter: blur(12px);
  border-bottom: 1px solid #f1f5f9;
  transition: box-shadow 0.3s ease, background 0.3s ease;
}
.nav-scrolled {
  background: rgba(255,255,255,0.97);
  box-shadow: 0 2px 20px rgba(0,0,0,0.07);
}
.nav-inner { max-width: 1200px; margin: 0 auto; padding: 0 32px; height: 64px; display: flex; align-items: center; gap: 32px; }
.nav-logo { display: flex; align-items: center; gap: 10px; text-decoration: none; flex-shrink: 0; }
.logo-mark { width: 36px; height: 36px; background: linear-gradient(135deg, #2872A1, #08BDDE); border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; overflow: hidden; }
.logo-mark.sm { width: 28px; height: 28px; border-radius: 8px; }
.logo-mark .logo-img { width: 100%; height: 100%; object-fit: cover; }
.logo-name { font-size: 16px; font-weight: 900; color: #1e293b; letter-spacing: 0.06em; display: block; line-height: 1; }
.logo-name.sm { font-size: 14px; color: #fff; }
.logo-tag  { font-size: 9.5px; font-weight: 600; color: #2872A1; display: block; margin-top: 1px; letter-spacing: 0.04em; }
.logo-tag.sm { color: rgba(255,255,255,0.7); }
.nav-links { display: flex; gap: 4px; flex: 1; }
.nav-link {
  padding: 8px 14px; font-size: 13.5px; font-weight: 500; color: #64748b;
  border-radius: 8px; text-decoration: none;
  transition: color 0.2s, background 0.2s;
  position: relative;
}
.nav-link {
  background: none;
  border: none;
  cursor: pointer;
  font-family: inherit;
}
.nav-link::after {
  content: '';
  position: absolute; bottom: 3px; left: 14px; right: 14px; height: 2px;
  background: linear-gradient(90deg, #2872A1, #08BDDE);
  border-radius: 99px;
  transform: scaleX(0);
  transition: transform 0.25s cubic-bezier(.22,.68,0,1.2);
}
.nav-link:hover { color: #2872A1; background: #eff8ff; }
.nav-link.active { color: #2872A1; font-weight: 700; }
.nav-link.active::after { transform: scaleX(1); }
.nav-actions { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
.btn-outline-nav {
  padding: 8px 18px; border: 1.5px solid #e2e8f0; border-radius: 99px;
  font-size: 13px; font-weight: 600; color: #475569; text-decoration: none;
  transition: border-color 0.2s, color 0.2s, transform 0.15s;
}
.btn-outline-nav:hover { border-color: #2872A1; color: #2872A1; transform: translateY(-1px); }
.btn-primary-nav {
  padding: 8px 20px; background: linear-gradient(135deg, #2872A1, #08BDDE);
  border-radius: 99px; font-size: 13px; font-weight: 700; color: #fff;
  text-decoration: none; transition: opacity 0.2s, transform 0.2s, box-shadow 0.2s;
  position: relative; overflow: hidden;
}
.btn-primary-nav:hover { opacity: 0.9; transform: translateY(-1px); box-shadow: 0 4px 16px rgba(40,114,161,0.3); }

/* ── HERO ── */
.hero { padding: 140px 32px 80px; position: relative; overflow: hidden; background: #f8fafc; min-height: 100vh; display: flex; align-items: center; }
.hero-bg { position: absolute; inset: 0; pointer-events: none; }
.hero-orb { position: absolute; border-radius: 50%; filter: blur(80px); opacity: 0.25; }
.orb1 { width: 500px; height: 500px; background: #2872A1; top: -100px; right: -100px; animation: orbDrift 8s ease-in-out infinite alternate; }
.orb2 { width: 350px; height: 350px; background: #08BDDE; bottom: 0; left: -80px;   animation: orbDrift 10s ease-in-out infinite alternate-reverse; }
@keyframes orbDrift {
  from { transform: translate(0, 0); }
  to   { transform: translate(30px, 20px); }
}
.hero-grid { position: absolute; inset: 0; background-image: linear-gradient(#e2e8f0 1px, transparent 1px), linear-gradient(90deg, #e2e8f0 1px, transparent 1px); background-size: 40px 40px; opacity: 0.4; }
.hero-inner { max-width: 1200px; margin: 0 auto; width: 100%; display: grid; grid-template-columns: 1fr 1fr; gap: 64px; align-items: center; position: relative; z-index: 1; }
.hero-badge { display: inline-flex; align-items: center; gap: 7px; background: #eff8ff; border: 1px solid #bae6fd; color: #2872A1; font-size: 12px; font-weight: 700; padding: 6px 14px; border-radius: 99px; margin-bottom: 20px; letter-spacing: 0.02em; }
.hero-title { font-size: 52px; font-weight: 900; line-height: 1.1; color: #0f172a; margin-bottom: 20px; letter-spacing: -0.02em; }
.hero-accent { background: linear-gradient(135deg, #2872A1, #08BDDE); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
.hero-sub { font-size: 16px; color: #64748b; line-height: 1.7; margin-bottom: 32px; max-width: 480px; }
.hero-cta { display: flex; gap: 12px; margin-bottom: 40px; flex-wrap: wrap; }
.cta-primary {
  display: inline-flex; align-items: center; gap: 8px;
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  color: #fff; padding: 13px 26px; border-radius: 99px;
  font-size: 14px; font-weight: 700; text-decoration: none;
  transition: transform 0.2s, box-shadow 0.2s, opacity 0.2s;
  box-shadow: 0 4px 20px rgba(40,114,161,0.35);
  position: relative; overflow: hidden;
}
.cta-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 28px rgba(40,114,161,0.45); }
.cta-primary.white { background: #fff; color: #2872A1; box-shadow: 0 4px 20px rgba(0,0,0,0.15); }
.cta-primary.white:hover { box-shadow: 0 8px 28px rgba(0,0,0,0.2); }
.cta-ghost {
  display: inline-flex; align-items: center; gap: 8px;
  background: #fff; color: #475569; padding: 13px 22px; border-radius: 99px;
  font-size: 14px; font-weight: 600; text-decoration: none;
  border: 1.5px solid #e2e8f0;
  transition: border-color 0.2s, color 0.2s, transform 0.2s;
}
.cta-ghost:hover { border-color: #2872A1; color: #2872A1; transform: translateY(-2px); }
.cta-ghost-white { font-size: 13px; font-weight: 500; color: rgba(255,255,255,0.8); text-decoration: none; display: flex; align-items: center; transition: color 0.2s; }
.cta-ghost-white:hover { color: #fff; text-decoration: underline; }
.hero-stats { display: flex; gap: 32px; }
.hstat { display: flex; flex-direction: column; animation: fadeUp 0.5s ease both; }
.hstat-val   { font-size: 24px; font-weight: 900; color: #0f172a; }
.hstat-label { font-size: 12px; color: #94a3b8; margin-top: 2px; font-weight: 500; }
@keyframes fadeUp {
  from { opacity: 0; transform: translateY(10px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* PREVIEW */
.hero-visual { position: relative; }
.preview-card {
  background: #fff; border-radius: 16px;
  box-shadow: 0 24px 64px rgba(0,0,0,0.14), 0 0 0 1px rgba(0,0,0,0.04);
  overflow: hidden;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}
.preview-card:hover { transform: translateY(-6px); box-shadow: 0 32px 80px rgba(0,0,0,0.18); }
.preview-topbar { background: #f1f5f9; padding: 10px 14px; display: flex; align-items: center; gap: 8px; border-bottom: 1px solid #e2e8f0; }
.preview-dots { display: flex; gap: 5px; }
.preview-dots span { width: 10px; height: 10px; border-radius: 50%; background: #e2e8f0; }
.preview-dots span:first-child  { background: #fca5a5; }
.preview-dots span:nth-child(2) { background: #fcd34d; }
.preview-dots span:nth-child(3) { background: #86efac; }
.preview-url { font-size: 11px; color: #94a3b8; flex: 1; text-align: center; font-weight: 500; }
.preview-body { display: flex; }
.preview-sidebar { width: 48px; background: #fff; border-right: 1px solid #f1f5f9; padding: 12px 8px; display: flex; flex-direction: column; gap: 8px; align-items: center; }
.ps-logo { width: 28px; height: 28px; border-radius: 8px; background: linear-gradient(135deg, #2872A1, #08BDDE); margin-bottom: 8px; }
.ps-item { width: 28px; height: 7px; border-radius: 4px; background: #f1f5f9; }
.ps-item.active { background: #bae6fd; }
.preview-main { flex: 1; padding: 14px; display: flex; flex-direction: column; gap: 10px; }
.preview-stats-row { display: flex; gap: 8px; }
.pstat { flex: 1; border-radius: 8px; padding: 8px 10px; display: flex; flex-direction: column; }
.pstat.blue  { background: #eff8ff; }
.pstat.sky   { background: #f0f9ff; }
.pstat.green { background: #f0fdf4; }
.pstat-num { font-size: 16px; font-weight: 800; color: #1e293b; }
.pstat-lbl { font-size: 9px; color: #94a3b8; margin-top: 1px; font-weight: 500; }
.preview-chart { background: #f8fafc; border-radius: 8px; padding: 8px 10px; }
.pc-label { font-size: 9px; color: #94a3b8; margin-bottom: 6px; font-weight: 600; }
.pc-bars { display: flex; align-items: flex-end; gap: 4px; height: 52px; }
.pc-bar { flex: 1; border-radius: 3px 3px 0 0; }
.preview-list-label { font-size: 9px; font-weight: 700; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.08em; }
.preview-list { display: flex; flex-direction: column; gap: 6px; }
.plist-row { display: flex; align-items: center; gap: 8px; padding: 6px 8px; border-radius: 7px; background: #f8fafc; transition: background 0.2s; }
.plist-row:hover { background: #eff8ff; }
.plist-avatar { width: 22px; height: 22px; border-radius: 50%; color: #fff; font-size: 9px; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.plist-info { flex: 1; }
.plist-name  { font-size: 10px; font-weight: 600; color: #1e293b; }
.plist-role  { font-size: 9px; color: #94a3b8; }
.plist-match { font-size: 11px; font-weight: 700; }
.float-badge { position: absolute; background: #fff; border-radius: 12px; padding: 9px 14px; display: flex; align-items: center; gap: 8px; font-size: 12px; font-weight: 600; color: #1e293b; box-shadow: 0 8px 24px rgba(0,0,0,0.12); white-space: nowrap; }
.fb1 { bottom: -16px; left: -32px; }
.fb2 { top: 48px; right: -28px; }

/* TRUST */
.trust-bar { padding: 32px; border-top: 1px solid #f1f5f9; border-bottom: 1px solid #f1f5f9; background: #fff; }
.trust-label { text-align: center; font-size: 12px; font-weight: 600; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 16px; }
.trust-logos { display: flex; justify-content: center; gap: 12px; flex-wrap: wrap; }
.trust-logo-pill { padding: 8px 20px; border: 1px solid #e2e8f0; border-radius: 99px; font-size: 13px; font-weight: 600; color: #94a3b8; transition: border-color 0.2s, color 0.2s, transform 0.2s; }
.trust-logo-pill:hover { border-color: #bae6fd; color: #2872A1; transform: translateY(-2px); }

/* SECTIONS */
.section { padding: 100px 32px; }
.section-alt { background: #f8fafc; }
.section-inner { max-width: 1200px; margin: 0 auto; }
.section-header { text-align: center; margin-bottom: 56px; }
.section-badge { display: inline-flex; align-items: center; gap: 7px; background: #eff8ff; border: 1px solid #bae6fd; color: #2872A1; font-size: 12px; font-weight: 700; padding: 6px 14px; border-radius: 99px; margin-bottom: 16px; }
.section-title { font-size: 40px; font-weight: 900; color: #0f172a; line-height: 1.15; letter-spacing: -0.02em; margin-bottom: 14px; }
.section-sub { font-size: 16px; color: #64748b; line-height: 1.7; max-width: 560px; margin: 0 auto; }
.accent { background: linear-gradient(135deg, #2872A1, #08BDDE); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }

/* FEATURES */
.features-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }
.feature-card { background: #fff; border: 1px solid #f1f5f9; border-radius: 16px; padding: 28px; transition: box-shadow 0.25s, transform 0.25s, border-color 0.25s; }
.feature-card:hover { box-shadow: 0 8px 32px rgba(0,0,0,0.08); transform: translateY(-6px); border-color: #bae6fd; }
.feature-icon-wrap { width: 48px; height: 48px; border-radius: 14px; display: flex; align-items: center; justify-content: center; margin-bottom: 16px; transition: transform 0.2s; }
.feature-card:hover .feature-icon-wrap { transform: scale(1.1); }
.feature-title { font-size: 16px; font-weight: 800; color: #0f172a; margin-bottom: 8px; }
.feature-desc  { font-size: 13.5px; color: #64748b; line-height: 1.6; }

/* STEPS */
.steps-row { display: flex; align-items: flex-start; gap: 0; position: relative; }
.step-card { flex: 1; padding: 32px 28px; background: #fff; border-radius: 16px; border: 1px solid #f1f5f9; position: relative; transition: box-shadow 0.25s, transform 0.25s; }
.step-card:hover { box-shadow: 0 8px 32px rgba(0,0,0,0.08); transform: translateY(-6px); }
.step-num { font-size: 42px; font-weight: 900; color: #f1f5f9; line-height: 1; margin-bottom: 16px; letter-spacing: -0.04em; }
.step-icon-wrap { width: 52px; height: 52px; border-radius: 16px; display: flex; align-items: center; justify-content: center; margin-bottom: 16px; transition: transform 0.2s; }
.step-card:hover .step-icon-wrap { transform: rotate(-6deg) scale(1.08); }
.step-title { font-size: 18px; font-weight: 800; color: #0f172a; margin-bottom: 10px; }
.step-desc  { font-size: 13.5px; color: #64748b; line-height: 1.6; }
.step-arrow { position: absolute; right: -20px; top: 50%; transform: translateY(-50%); z-index: 1; background: #fff; border-radius: 50%; padding: 4px; }

/* SPLIT */
.split-layout { display: grid; grid-template-columns: 1fr 1fr; gap: 72px; align-items: center; }
.split-layout.reverse { direction: rtl; }
.split-layout.reverse > * { direction: ltr; }
.check-list  { list-style: none; display: flex; flex-direction: column; gap: 10px; margin-top: 24px; }
.check-item  { display: flex; align-items: center; gap: 10px; font-size: 14px; font-weight: 500; color: #475569; }
.check-icon  { width: 22px; height: 22px; border-radius: 6px; background: #eff8ff; display: flex; align-items: center; justify-content: center; flex-shrink: 0; transition: background 0.2s, transform 0.2s; }
.check-item:hover .check-icon { background: #bae6fd; transform: scale(1.1); }
.image-placeholder { width: 100%; aspect-ratio: 4/3; background: #f8fafc; border: 2px dashed #e2e8f0; border-radius: 20px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px; color: #cbd5e1; transition: border-color 0.2s, background 0.2s; }
.image-placeholder:hover { border-color: #bae6fd; background: #f0f9ff; }
.image-placeholder p    { font-size: 15px; font-weight: 600; color: #94a3b8; }
.image-placeholder span { font-size: 12px; color: #cbd5e1; }

/* DARK */
.section-dark { background: linear-gradient(135deg, #0f172a 0%, #1e3a5f 60%, #0e4d6e 100%); }
.dark-badge  { background: rgba(8,189,222,0.1); border-color: rgba(8,189,222,0.3); color: #08BDDE; }
.light-title { color: #f1f5f9; }
.sky-accent  { color: #08BDDE; -webkit-text-fill-color: #08BDDE; }
.benefits-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; }
.benefit-card { background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08); border-radius: 16px; padding: 28px 24px; transition: background 0.25s, transform 0.25s, border-color 0.25s; }
.benefit-card:hover { background: rgba(255,255,255,0.09); transform: translateY(-6px); border-color: rgba(8,189,222,0.3); }
.benefit-icon { width: 52px; height: 52px; border-radius: 14px; background: rgba(8,189,222,0.1); display: flex; align-items: center; justify-content: center; margin-bottom: 16px; transition: background 0.2s, transform 0.2s; }
.benefit-card:hover .benefit-icon { background: rgba(8,189,222,0.18); transform: scale(1.08); }
.benefit-title { font-size: 16px; font-weight: 800; color: #f1f5f9; margin-bottom: 8px; }
.benefit-desc  { font-size: 13px; color: rgba(255,255,255,0.55); line-height: 1.6; }

/* CTA */
.cta-section { padding: 100px 32px; background: linear-gradient(135deg, #2872A1, #08BDDE); position: relative; overflow: hidden; }
.cta-inner { max-width: 1200px; margin: 0 auto; position: relative; z-index: 1; }
.cta-orb { position: absolute; border-radius: 50%; opacity: 0.15; filter: blur(60px); }
.c1 { width: 400px; height: 400px; background: #fff; top: -100px; left: -100px; animation: orbDrift 9s ease-in-out infinite alternate; }
.c2 { width: 300px; height: 300px; background: #0f172a; bottom: -80px; right: -80px; animation: orbDrift 7s ease-in-out infinite alternate-reverse; }
.cta-content { text-align: center; }
.cta-title { font-size: 42px; font-weight: 900; color: #fff; margin-bottom: 14px; letter-spacing: -0.02em; }
.cta-sub    { font-size: 16px; color: rgba(255,255,255,0.8); margin-bottom: 32px; }
.cta-buttons { display: flex; align-items: center; justify-content: center; gap: 20px; flex-wrap: wrap; }

/* FOOTER */
.footer { background: #0f172a; padding: 64px 32px 0; }
.footer-inner { max-width: 1200px; margin: 0 auto; display: grid; grid-template-columns: 2fr 1fr 1fr 1fr; gap: 48px; padding-bottom: 48px; border-bottom: 1px solid rgba(255,255,255,0.07); }
.footer-brand { display: flex; flex-direction: column; gap: 16px; }
.footer-logo  { display: flex; align-items: center; gap: 10px; }
.footer-tagline { font-size: 13px; color: rgba(255,255,255,0.45); line-height: 1.6; }
.footer-links-group { display: flex; flex-direction: column; gap: 12px; }
.footer-group-title { font-size: 11px; font-weight: 700; color: rgba(255,255,255,0.4); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 4px; }
.footer-link { font-size: 13.5px; color: rgba(255,255,255,0.6); text-decoration: none; transition: color 0.2s, transform 0.2s; display: inline-block; }
.footer-link:hover { color: #08BDDE; transform: translateX(3px); }
.footer-bottom { max-width: 1200px; margin: 0 auto; padding: 20px 0; display: flex; align-items: center; justify-content: space-between; font-size: 12px; color: rgba(255,255,255,0.3); }
.footer-bottom-links { display: flex; gap: 20px; }
.footer-bottom-links a { color: rgba(255,255,255,0.3); text-decoration: none; transition: color 0.2s; }
.footer-bottom-links a:hover { color: rgba(255,255,255,0.6); }

/* SCROLL TOP BTN */
.scroll-top-btn {
  position: fixed; bottom: 28px; right: 28px; z-index: 200;
  width: 44px; height: 44px; border-radius: 50%;
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  color: #fff; border: none; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 4px 16px rgba(40,114,161,0.4);
  opacity: 0; pointer-events: none;
  transform: translateY(12px);
  transition: opacity 0.3s, transform 0.3s;
}
.scroll-top-btn.visible { opacity: 1; pointer-events: auto; transform: translateY(0); }
.scroll-top-btn:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(40,114,161,0.5); }

/* ripple-btn base */
.ripple-btn { position: relative; overflow: hidden; }

/* CAROUSEL */
.carousel-wrap {
  position: relative;
  width: 100%;
  aspect-ratio: 800 / 519;
  overflow: hidden;
  box-shadow: 0 16px 48px rgba(0,0,0,0.12);
}
.carousel-img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: contain;
  opacity: 0;
  transition: opacity 0.7s ease;
}
.carousel-img.active {
  opacity: 1;
}

.match-img {
  width: 100%;
  height: 900px;
  object-fit: contain;
  border-radius: 20px;
}
.split-image-wrap {
  min-height: 700px;    /* adjust as needed */
}

/* Carousel arrows */
.carousel-arrow {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  z-index: 10;
  width: 38px;
  height: 38px;
  border-radius: 50%;
  border: none;
  background: rgba(255,255,255,0.92);
  color: #1e293b;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  box-shadow: 0 4px 14px rgba(0,0,0,0.15);
  transition: background 0.2s, transform 0.2s, box-shadow 0.2s;
}
.carousel-arrow:hover {
  background: #fff;
  box-shadow: 0 6px 20px rgba(0,0,0,0.2);
  transform: translateY(-50%) scale(1.08);
}
.carousel-arrow.left  { left: 12px; }
.carousel-arrow.right { right: 12px; }

/* Dots */
.carousel-dots {
  position: absolute;
  bottom: 14px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  gap: 7px;
  z-index: 10;
}
.carousel-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  border: none;
  background: rgba(255,255,255,0.5);
  cursor: pointer;
  transition: background 0.25s, transform 0.25s;
  padding: 0;
}
.carousel-dot.active {
  background: #fff;
  transform: scale(1.35);
}
</style>