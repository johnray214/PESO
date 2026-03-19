<template>
  <div class="auth-wrapper">

    <!-- LEFT PANEL -->
    <div class="left-panel">
      <div class="orb orb1"></div>
      <div class="orb orb2"></div>
      <div class="orb orb3"></div>

      <div class="panel-top">
        <div class="brand">
          <div class="brand-mark">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5">
              <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
              <circle cx="9" cy="7" r="4"/>
              <path d="M23 21v-2a4 4 0 00-3-3.87"/>
              <path d="M16 3.13a4 4 0 010 7.75"/>
            </svg>
          </div>
          <div>
            <span class="brand-name">PESO</span>
            <span class="brand-tag">Employer Portal</span>
          </div>
        </div>

        <div>
          <h1 class="panel-headline">Start hiring <span class="sky">smarter</span><br/>with PESO.</h1>
          <p class="panel-sub">Register your company and connect with thousands of job-ready applicants across the Philippines — completely free.</p>
        </div>

        <div class="panel-stats">
          <div v-for="s in stats" :key="s.label" class="pstat">
            <span class="pstat-val">{{ s.val }}</span>
            <span class="pstat-label">{{ s.label }}</span>
          </div>
        </div>
      </div>

      <div class="side-steps">
        <div v-for="(s, i) in stepLabels" :key="s.title" class="side-step"
          :class="{ active: currentStep === i+1, done: currentStep > i+1 }">
          <div class="side-step-dot">
            <svg v-if="currentStep > i+1" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
            <span v-else>{{ i + 1 }}</span>
          </div>
          <div class="side-step-info">
            <p class="side-step-title">{{ s.title }}</p>
            <p class="side-step-sub">{{ s.sub }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- RIGHT PANEL -->
    <div class="right-panel">
      <div class="auth-box">
        <!-- ✅ SUCCESS SCREEN -->
        <div v-if="registered" class="success-screen">
          <div class="success-icon">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
          </div>
          <h2 class="success-title">Application Submitted!</h2>
          <p class="success-desc">
            Thank you for registering with PESO. Your application is now <strong>pending review</strong> by our staff.
          </p>
          <div class="success-email-badge">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
            {{ registeredEmail }}
          </div>
          <div class="success-steps">
            <div class="success-step">
              <div class="sstep-num">1</div>
              <div class="sstep-text">
                <p class="sstep-title">Account Under Review</p>
                <p class="sstep-sub">PESO staff will verify your documents within 1–2 business days</p>
              </div>
            </div>
            <div class="success-step">
              <div class="sstep-num">2</div>
              <div class="sstep-text">
                <p class="sstep-title">Confirmation Email</p>
                <p class="sstep-sub">You'll receive an email once your account is approved</p>
              </div>
            </div>
            <div class="success-step">
              <div class="sstep-num">3</div>
              <div class="sstep-text">
                <p class="sstep-title">Start Hiring</p>
                <p class="sstep-sub">Log in and post jobs to connect with qualified applicants</p>
              </div>
            </div>
          </div>
          <router-link to="/employer/login" class="btn-go-login">
            Go to Login
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
          </router-link>
        </div>

        <template v-else>
          <div class="form-header">
            <div class="step-badge">Step {{ currentStep }} of 3</div>
            <h2 class="form-title">{{ stepLabels[currentStep - 1].title }}</h2>
            <p class="form-sub">{{ stepLabels[currentStep - 1].sub }}</p>
          </div>

          <div class="gov-badge">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#2872A1" stroke-width="2" style="flex-shrink:0">
              <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
            </svg>
            <span class="gov-badge-text"><strong>Official government platform.</strong> Accounts are reviewed and verified by PESO before activation.</span>
          </div>

          <!-- ── STEP 1: Account Setup ── -->
          <div v-if="currentStep === 1" class="step-body">
            <div class="form-group">
              <label class="form-label">Work Email Address</label>
              <div class="input-wrap">
                <span class="input-icon">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                </span>
                <input class="form-input" :class="{ 'input-error': emailError }" type="email"
                  v-model="form.email" @blur="validateEmail" placeholder="hr@yourcompany.com.ph"/>
              </div>
              <p v-if="emailError" class="field-error">{{ emailError }}</p>
            </div>

            <div class="form-group">
              <label class="form-label">Password</label>
              <div class="input-wrap">
                <span class="input-icon">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                </span>
                <input class="form-input" :type="showPw ? 'text' : 'password'" v-model="form.password" placeholder="Min. 8 characters"/>
                <button class="pw-toggle" @click="showPw = !showPw" type="button">
                  <svg v-if="!showPw" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                </button>
              </div>
            </div>

            <div class="form-group">
              <label class="form-label">Confirm Password</label>
              <div class="input-wrap">
                <span class="input-icon">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                </span>
                <input class="form-input" :class="{ 'input-error': passwordError }"
                  :type="showConfirmPw ? 'text' : 'password'" v-model="form.confirmPassword"
                  @blur="validatePassword" placeholder="Repeat password"/>
                <button class="pw-toggle" @click="showConfirmPw = !showConfirmPw" type="button">
                  <svg v-if="!showConfirmPw" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                </button>
              </div>
              <p v-if="passwordError" class="field-error">{{ passwordError }}</p>
            </div>
          </div>

          <!-- ── STEP 2: Company Info ── -->
          <div v-if="currentStep === 2" class="step-body">
            <div class="form-group">
              <label class="form-label">Company / Business Name</label>
              <div class="input-wrap">
                <span class="input-icon">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>
                </span>
                <input class="form-input" type="text" v-model="form.companyName" placeholder="Nexus Tech Solutions Inc."/>
              </div>
            </div>

            <div class="form-group">
              <label class="form-label">Contact Person</label>
              <div class="input-wrap">
                <span class="input-icon">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                </span>
                <input class="form-input" type="text" v-model="form.contactPerson" placeholder="Juan Dela Cruz"/>
              </div>
            </div>

            <div class="form-row-2">
              <div class="form-group">
                <label class="form-label">Industry</label>
                <div class="autocomplete-wrap">
                  <input class="form-input" type="text" v-model="form.industry"
                    placeholder="Type to search..."
                    @input="showIndustrySuggestions = true"
                    @blur="hideIndustrySuggestions"
                    autocomplete="off"/>
                  <div v-if="showIndustrySuggestions && filteredIndustries.length" class="autocomplete-dropdown">
                    <div v-for="ind in filteredIndustries" :key="ind" class="autocomplete-item"
                      @mousedown.prevent="selectIndustry(ind)">
                      {{ ind }}
                    </div>
                  </div>
                </div>
              </div>
              <div class="form-group">
                <label class="form-label">Company Size</label>
                <select class="form-select" v-model="form.companySize">
                  <option value="">Employees</option>
                  <option>1–10</option>
                  <option>11–50</option>
                  <option>50–100</option>
                  <option>100–500</option>
                  <option>500+</option>
                </select>
              </div>
            </div>

            <!-- Province -->
            <div class="form-group">
              <label class="form-label">Province</label>
              <select class="form-select" v-model="form.provinceCode" @change="onProvinceChange">
                <option value="">Select province...</option>
                <option v-for="p in provinces" :key="p.prov_code" :value="p.prov_code">
                  {{ p.name }}
                </option>
              </select>
            </div>

            <!-- City / Municipality -->
            <div class="form-group">
              <label class="form-label">City / Municipality</label>
              <select class="form-select" v-model="form.cityCode" @change="onCityChange" :disabled="!cities.length">
                <option value="">{{ form.provinceCode ? 'Select city / municipality...' : 'Select province first' }}</option>
                <option v-for="c in cities" :key="c.mun_code" :value="c.mun_code">
                  {{ c.name }}
                </option>
              </select>
            </div>

            <!-- Barangay -->
            <div class="form-group">
              <label class="form-label">Barangay</label>
              <select class="form-select" v-model="form.barangay" :disabled="!barangays.length">
                <option value="">{{ form.cityCode ? 'Select barangay...' : 'Select city first' }}</option>
                <option v-for="b in barangays" :key="b.brgy_code" :value="b.name">
                  {{ b.name }}
                </option>
              </select>
            </div>

            <div class="form-row-2">
              <div class="form-group">
                <label class="form-label">Contact Number</label>
                <div class="input-wrap">
                  <span class="input-icon">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 9.8 19.79 19.79 0 01.07 1.2 2 2 0 012.05 0h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L6.09 7.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 14.92z"/></svg>
                  </span>
                  <input class="form-input" type="tel" v-model="form.phone" placeholder="+63 917 000 0000"/>
                </div>
              </div>
              <div class="form-group">
                <label class="form-label">TIN / Registration No.</label>
                <div class="input-wrap">
                  <span class="input-icon">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                  </span>
                  <input class="form-input" type="text" v-model="form.tin" placeholder="123-456-789-000"/>
                </div>
              </div>
            </div>

            <div class="form-group">
              <label class="form-label">Website <span class="optional-tag">Optional</span></label>
              <div class="input-wrap">
                <span class="input-icon">
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 014 10 15.3 15.3 0 01-4 10 15.3 15.3 0 01-4-10 15.3 15.3 0 014-10z"/></svg>
                </span>
                <input class="form-input" type="url" v-model="form.website" placeholder="www.yourcompany.com.ph"/>
              </div>
            </div>
          </div>

          <!-- ── STEP 3: Documents ── -->
          <div v-if="currentStep === 3" class="step-body">
            <div class="form-group">
              <label class="form-label">Business Permit / DTI Registration</label>
              <div class="upload-area" @click="$refs.bizPermit.click()" :class="{ 'has-file': form.bizPermitFile }">
                <div v-if="!bizPermitPreview" class="upload-inner">
                  <div class="upload-icon">
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                  </div>
                  <p class="upload-label">Click to upload or drag & drop</p>
                  <p class="upload-sub">PDF, JPG, PNG — max 2MB</p>
                </div>
                <div v-else class="file-preview">
                  <img v-if="bizPermitPreview !== 'pdf'" :src="bizPermitPreview" class="preview-img"/>
                  <div v-else class="pdf-preview">
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                    <span>{{ form.bizPermitFile?.name }}</span>
                  </div>
                  <button class="remove-file-btn" @click.stop="removeFile('bizPermit')" type="button">✕ Remove</button>
                </div>
                <input ref="bizPermit" type="file" accept=".pdf,.jpg,.jpeg,.png" style="display:none"
                  @change="handleFileUpload('bizPermit', $event)"/>
              </div>
              <p v-if="bizPermitError" class="field-error">{{ bizPermitError }}</p>
            </div>

            <div class="form-group">
              <label class="form-label">BIR Certificate of Registration <span class="optional-tag">Optional</span></label>
              <div class="upload-area" @click="$refs.birCert.click()" :class="{ 'has-file': form.birCertFile }">
                <div v-if="!birCertPreview" class="upload-inner">
                  <div class="upload-icon">
                    <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                  </div>
                  <p class="upload-label">Click to upload or drag & drop</p>
                  <p class="upload-sub">PDF, JPG, PNG — max 2MB</p>
                </div>
                <div v-else class="file-preview">
                  <img v-if="birCertPreview !== 'pdf'" :src="birCertPreview" class="preview-img"/>
                  <div v-else class="pdf-preview">
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="1.5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                    <span>{{ form.birCertFile?.name }}</span>
                  </div>
                  <button class="remove-file-btn" @click.stop="removeFile('birCert')" type="button">✕ Remove</button>
                </div>
                <input ref="birCert" type="file" accept=".pdf,.jpg,.jpeg,.png" style="display:none"
                  @change="handleFileUpload('birCert', $event)"/>
              </div>
            </div>

            <div class="verify-box">
              <div class="verify-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
              </div>
              <p class="verify-title">Almost there!</p>
              <p class="verify-desc">Your application will be reviewed by PESO within <strong>1–2 business days</strong>. You'll receive a confirmation at:</p>
              <span class="verify-email-badge">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                {{ form.email || 'your@email.com' }}
              </span>
            </div>
          </div>

        <!-- Navigation -->
        <div class="step-nav">
          <button v-if="currentStep > 1" class="btn-back" @click="currentStep--">← Back</button>
          <button v-if="currentStep < 3" class="btn-next" @click="nextStep">
            Continue
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
          </button>
          <button v-if="currentStep === 3" class="btn-next btn-green" @click="handleSubmit" :disabled="loading">
            <span v-if="loading" style="display:flex;align-items:center;gap:8px;">
              <span class="spinner"></span>
              Submitting…
            </span>
            <span v-else style="display:flex;align-items:center;gap:6px;">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
              Submit Application
            </span>
          </button>
        </div>

        <p v-if="error" style="color:#dc2626;font-size:12.5px;background:#fef2f2;border:1px solid #fecaca;border-radius:8px;padding:10px 14px;margin-top:10px;">{{ error }}</p>

        <p class="terms-note">
          By registering, you agree to PESO's
          <a href="#">Terms of Service</a> and <a href="#">Privacy Policy</a>.
        </p>

        <p class="switch-link">
          Already have an account?
          <router-link to="/employer/login">Sign in →</router-link>
        </p>
       </template>
      </div>
    </div>

  </div>
</template>

<script>
import phil from 'phil-reg-prov-mun-brgy'
import api from '@/services/api'

export default {
  name: 'EmployerRegister',

  data() {
    return {
      currentStep: 1,
      showPw: false,
      showConfirmPw: false,
      loading: false,
      error: '',

      emailError: '',
      passwordError: '',
      bizPermitError: '',

      bizPermitPreview: null,
      birCertPreview: null,

      provinces: [],
      cities: [],
      barangays: [],

      registered: false,
      registeredEmail: '',

      showIndustrySuggestions: false,

      form: {
        email: '',
        password: '',
        confirmPassword: '',
        companyName: '',
        contactPerson: '',
        industry: '',
        companySize: '',
        provinceCode: '',
        cityCode: '',
        province: '',
        city: '',
        barangay: '',
        phone: '',
        tin: '',
        website: '',
        bizPermitFile: null,
        birCertFile: null,
      },

      stats: [
        { val: '5,000+', label: 'Active Jobseekers' },
        { val: '300+',   label: 'Employers' },
        { val: '1,200+', label: 'Hires Made' },
      ],

      stepLabels: [
        { title: 'Account Setup',          sub: 'Create your login credentials' },
        { title: 'Company Information',    sub: 'Tell us about your business' },
        { title: 'Verification Documents', sub: 'Upload your business documents' },
      ],

      industries: [
        'IT / Software', 'BPO / Call Center', 'Retail / Commerce',
        'Healthcare', 'Finance / Banking', 'Manufacturing',
        'Education', 'Food & Beverage', 'Construction',
        'Government', 'Logistics / Transport', 'Real Estate',
        'Tourism / Hospitality', 'Agriculture', 'Other',
      ],
    }
  },

  computed: {
    filteredIndustries() {
      if (!this.form.industry) return this.industries
      return this.industries.filter(i =>
        i.toLowerCase().includes(this.form.industry.toLowerCase())
      )
    },
  },

  mounted() {
    this.provinces = [...phil.provinces].sort((a, b) => a.name.localeCompare(b.name))
  },

  methods: {
    validateEmail() {
      const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      this.emailError = re.test(this.form.email)
        ? '' : 'Please enter a valid email address.'
    },

    validatePassword() {
      if (this.form.password.length < 8) {
        this.passwordError = 'Password must be at least 8 characters.'
        return
      }
      this.passwordError = this.form.password !== this.form.confirmPassword
        ? 'Passwords do not match.' : ''
    },

    nextStep() {
      if (this.currentStep === 1) {
        this.validateEmail()
        this.validatePassword()
        if (this.emailError || this.passwordError) return
      }
      if (this.currentStep === 2) {
        if (!this.form.companyName)   { this.error = 'Company name is required.'; return }
        if (!this.form.contactPerson) { this.error = 'Contact person is required.'; return }
        if (!this.form.industry)      { this.error = 'Industry is required.'; return }
        if (!this.form.companySize)   { this.error = 'Company size is required.'; return }
        if (!this.form.province)      { this.error = 'Province is required.'; return }
        if (!this.form.city)          { this.error = 'City / Municipality is required.'; return }
        if (!this.form.barangay)      { this.error = 'Barangay is required.'; return }
        if (!this.form.phone)         { this.error = 'Contact number is required.'; return }
        this.error = ''
      }
      this.currentStep++
    },

    selectIndustry(ind) {
      this.form.industry = ind
      this.showIndustrySuggestions = false
    },

    hideIndustrySuggestions() {
      setTimeout(() => { this.showIndustrySuggestions = false }, 150)
    },

    onProvinceChange() {
      this.form.cityCode = ''
      this.form.city     = ''
      this.form.barangay = ''
      this.cities        = []
      this.barangays     = []

      if (!this.form.provinceCode) return

      const selected = this.provinces.find(p => p.prov_code === this.form.provinceCode)
      this.form.province = selected?.name || ''
      this.cities = [...phil.getCityMunByProvince(this.form.provinceCode)]
      .sort((a, b) => a.name.localeCompare(b.name))
    },

    onCityChange() {
      this.form.barangay = ''
      this.barangays     = []

      if (!this.form.cityCode) return

      const selected = this.cities.find(c => c.mun_code === this.form.cityCode)
      this.form.city = selected?.name || ''
      this.barangays = [...phil.getBarangayByMun(this.form.cityCode)]
       .sort((a, b) => a.name.localeCompare(b.name))
    },

    handleFileUpload(type, event) {
      const file = event.target.files[0]
      if (!file) return

      if (file.size > 2 * 1024 * 1024) {
        if (type === 'bizPermit') this.bizPermitError = 'File must be under 2MB.'
        return
      }

      if (type === 'bizPermit') {
        this.bizPermitError     = ''
        this.form.bizPermitFile = file
        if (file.type === 'application/pdf') {
          this.bizPermitPreview = 'pdf'
        } else {
          const reader = new FileReader()
          reader.onload = e => { this.bizPermitPreview = e.target.result }
          reader.readAsDataURL(file)
        }
      } else {
        this.form.birCertFile = file
        if (file.type === 'application/pdf') {
          this.birCertPreview = 'pdf'
        } else {
          const reader = new FileReader()
          reader.onload = e => { this.birCertPreview = e.target.result }
          reader.readAsDataURL(file)
        }
      }
    },

    removeFile(type) {
      if (type === 'bizPermit') {
        this.form.bizPermitFile = null
        this.bizPermitPreview   = null
        this.$refs.bizPermit.value = ''
      } else {
        this.form.birCertFile = null
        this.birCertPreview   = null
        this.$refs.birCert.value = ''
      }
    },

    async handleSubmit() {
      if (!this.form.bizPermitFile) {
        this.bizPermitError = 'Business Permit is required.'
        return
      }

      this.loading = true
      this.error   = ''

      try {
        const fd = new FormData()
        fd.append('email',                 this.form.email)
        fd.append('password',              this.form.password)
        fd.append('password_confirmation', this.form.confirmPassword)
        fd.append('company_name',          this.form.companyName)
        fd.append('contact_person',        this.form.contactPerson)
        fd.append('industry',              this.form.industry)
        fd.append('company_size',          this.form.companySize)
        fd.append('province',              this.form.province)
        fd.append('city',                  this.form.city)
        fd.append('barangay',              this.form.barangay)
        fd.append('address_full',          [this.form.barangay, this.form.city, this.form.province].filter(Boolean).join(', '))
        fd.append('phone',                 this.form.phone)
        fd.append('tin',                   this.form.tin)
        fd.append('website',               this.form.website)
        fd.append('biz_permit',            this.form.bizPermitFile)
        if (this.form.birCertFile) fd.append('bir_cert', this.form.birCertFile)

        await api.post('/employer/register', fd, {
          headers: { 'Content-Type': 'multipart/form-data' },
        })

        this.registered      = true
        this.registeredEmail = this.form.email

      } catch (e) {
        const errs = e.response?.data?.errors
        this.error = errs
          ? Object.values(errs).flat().join(' ')
          : (e.response?.data?.message || 'Registration failed. Please try again.')
      } finally {
        this.loading = false
      }
    },
  },
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap');
* { box-sizing: border-box; margin: 0; padding: 0; }

.auth-wrapper { font-family: 'Plus Jakarta Sans', sans-serif; display: flex; min-height: 100vh; overflow: hidden; }

/* ── LEFT PANEL ── */
.left-panel { width: 46%; min-height: 100vh; background: linear-gradient(145deg, #0f172a 0%, #1a3a5c 55%, #0e4d6e 100%); position: relative; display: flex; flex-direction: column; justify-content: flex-start; gap: 36px; padding: 44px 52px; overflow: hidden; flex-shrink: 0; }
.left-panel::before { content: ''; position: absolute; inset: 0; background-image: linear-gradient(rgba(8,189,222,0.07) 1px, transparent 1px), linear-gradient(90deg, rgba(8,189,222,0.07) 1px, transparent 1px); background-size: 44px 44px; }
.orb { position: absolute; border-radius: 50%; filter: blur(80px); pointer-events: none; }
.orb1 { width: 360px; height: 360px; background: #2872A1; opacity: 0.22; top: -80px; right: -80px; }
.orb2 { width: 260px; height: 260px; background: #08BDDE; opacity: 0.16; bottom: -60px; left: -60px; }
.orb3 { width: 180px; height: 180px; background: #0ea5e9; opacity: 0.1; top: 50%; left: 50%; transform: translate(-50%, -50%); }

.panel-top { position: relative; z-index: 1; display: flex; flex-direction: column; gap: 28px; }
.brand { display: flex; align-items: center; gap: 12px; }
.brand-mark { width: 44px; height: 44px; border-radius: 13px; background: linear-gradient(135deg, #2872A1, #08BDDE); display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 16px rgba(8,189,222,0.35); flex-shrink: 0; }
.brand-name { font-size: 18px; font-weight: 900; color: #fff; letter-spacing: 0.07em; display: block; line-height: 1; }
.brand-tag  { font-size: 10px; font-weight: 600; color: rgba(8,189,222,0.85); display: block; margin-top: 2px; }

.panel-headline { font-size: 36px; font-weight: 900; color: #fff; line-height: 1.12; letter-spacing: -0.025em; margin-bottom: 12px; }
.panel-headline .sky { background: linear-gradient(90deg, #08BDDE, #38bdf8); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }
.panel-sub { font-size: 13.5px; color: rgba(255,255,255,0.5); line-height: 1.7; }

.panel-stats { display: flex; gap: 0; }
.pstat { display: flex; flex-direction: column; }
.pstat + .pstat { padding-left: 20px; margin-left: 20px; border-left: 1px solid rgba(255,255,255,0.1); }
.pstat-val   { font-size: 22px; font-weight: 900; color: #fff; }
.pstat-label { font-size: 11px; color: rgba(255,255,255,0.4); margin-top: 2px; font-weight: 500; }

.side-steps { position: relative; z-index: 1; display: flex; flex-direction: column; gap: 0; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08); border-radius: 16px; padding: 18px 20px; }
.side-step { display: flex; align-items: flex-start; gap: 14px; padding: 10px 0; border-bottom: 1px solid rgba(255,255,255,0.06); opacity: 0.45; transition: opacity 0.2s; }
.side-step:last-child { border-bottom: none; }
.side-step.active { opacity: 1; }
.side-step.done   { opacity: 0.65; }
.side-step-dot { width: 26px; height: 26px; border-radius: 50%; background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.15); display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 800; color: rgba(255,255,255,0.5); flex-shrink: 0; transition: all 0.2s; }
.side-step.active .side-step-dot { background: linear-gradient(135deg, #2872A1, #08BDDE); border-color: #08BDDE; color: #fff; box-shadow: 0 0 0 3px rgba(8,189,222,0.25); }
.side-step.done .side-step-dot { background: rgba(34,197,94,0.2); border-color: rgba(34,197,94,0.4); color: #4ade80; }
.side-step-title { font-size: 12.5px; font-weight: 700; color: #f1f5f9; }
.side-step-sub   { font-size: 11px; color: rgba(255,255,255,0.4); margin-top: 2px; }

/* ── RIGHT PANEL ── */
.right-panel { flex: 1; display: flex; align-items: center; justify-content: center; padding: 48px 52px; overflow-y: auto; background: #f8fafc; }
.auth-box { width: 100%; max-width: 460px; }

.form-header { margin-bottom: 20px; }
.step-badge { display: inline-block; background: #eff8ff; border: 1px solid #bae6fd; color: #2872A1; font-size: 11px; font-weight: 700; padding: 4px 12px; border-radius: 99px; margin-bottom: 10px; letter-spacing: 0.04em; }
.form-title { font-size: 26px; font-weight: 900; color: #0f172a; letter-spacing: -0.02em; margin-bottom: 4px; }
.form-sub   { font-size: 13.5px; color: #64748b; line-height: 1.6; }

.gov-badge { display: flex; align-items: flex-start; gap: 10px; background: #eff8ff; border: 1px solid #bae6fd; border-radius: 10px; padding: 11px 14px; margin-bottom: 20px; }
.gov-badge-text { font-size: 12px; color: #1a5f8a; line-height: 1.5; }
.gov-badge-text strong { color: #2872A1; }

.step-body { display: flex; flex-direction: column; }
.form-group { margin-bottom: 14px; display: flex; flex-direction: column; gap: 6px; }
.form-label { font-size: 11.5px; font-weight: 700; color: #475569; text-transform: uppercase; letter-spacing: 0.06em; }
.optional-tag { font-weight: 500; color: #94a3b8; text-transform: none; font-size: 10.5px; margin-left: 4px; }

.input-wrap { position: relative; }
.input-icon { position: absolute; left: 13px; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none; display: flex; }
.form-input { width: 100%; padding: 11px 14px 11px 40px; border: 1.5px solid #e2e8f0; border-radius: 10px; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13.5px; color: #1e293b; background: #fff; outline: none; transition: border 0.15s, box-shadow 0.15s; }
.form-input:focus { border-color: #08BDDE; box-shadow: 0 0 0 3px rgba(8,189,222,0.1); }
.form-input::placeholder { color: #cbd5e1; }
.form-input.input-error { border-color: #ef4444 !important; }

.form-select { width: 100%; padding: 11px 38px 11px 14px; border: 1.5px solid #e2e8f0; border-radius: 10px; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13.5px; color: #1e293b; background: #fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E") no-repeat right 14px center; outline: none; appearance: none; cursor: pointer; transition: border 0.15s; }
.form-select:focus { border-color: #08BDDE; box-shadow: 0 0 0 3px rgba(8,189,222,0.1); }
.form-select:disabled { background-color: #f8fafc; color: #94a3b8; cursor: not-allowed; }

.pw-toggle { position: absolute; right: 13px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: #94a3b8; padding: 2px; display: flex; align-items: center; }
.pw-toggle:hover { color: #475569; }

.form-row-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.field-error { font-size: 11.5px; color: #ef4444; margin-top: 2px; }

/* ── AUTOCOMPLETE ── */
.autocomplete-wrap { position: relative; }
.autocomplete-dropdown { position: absolute; top: calc(100% + 4px); left: 0; right: 0; background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; box-shadow: 0 8px 24px rgba(0,0,0,0.1); z-index: 50; max-height: 200px; overflow-y: auto; }
.autocomplete-item { padding: 10px 14px; font-size: 13px; color: #475569; cursor: pointer; transition: background 0.12s; }
.autocomplete-item:hover { background: #f0f9ff; color: #2872A1; }

/* ── UPLOAD ── */
.upload-area { border: 2px dashed #e2e8f0; border-radius: 10px; padding: 20px; text-align: center; cursor: pointer; transition: all 0.15s; background: #fafafa; }
.upload-area:hover { border-color: #08BDDE; background: #f0f9ff; }
.upload-area.has-file { border-color: #08BDDE; border-style: solid; background: #f0f9ff; }
.upload-inner { display: flex; flex-direction: column; align-items: center; }
.upload-icon { color: #94a3b8; margin-bottom: 6px; display: flex; justify-content: center; }
.upload-label { font-size: 13px; font-weight: 600; color: #475569; }
.upload-sub { font-size: 11px; color: #94a3b8; margin-top: 3px; }
.file-preview { display: flex; flex-direction: column; align-items: center; gap: 8px; width: 100%; }
.preview-img { max-height: 120px; max-width: 100%; border-radius: 8px; object-fit: contain; }
.pdf-preview { display: flex; align-items: center; gap: 8px; font-size: 12px; color: #ef4444; font-weight: 600; }
.remove-file-btn { background: #fef2f2; color: #ef4444; border: 1px solid #fecaca; border-radius: 6px; padding: 4px 10px; font-size: 11.5px; font-weight: 600; cursor: pointer; font-family: inherit; }
.remove-file-btn:hover { background: #fee2e2; }

/* ── VERIFY BOX ── */
.verify-box { background: linear-gradient(135deg, #f0fdf4, #ecfdf5); border: 1.5px solid #bbf7d0; border-radius: 14px; padding: 20px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 10px; margin-top: 8px; }
.verify-icon { width: 50px; height: 50px; border-radius: 50%; background: linear-gradient(135deg, #22c55e, #16a34a); display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 14px rgba(34,197,94,0.3); }
.verify-title { font-size: 16px; font-weight: 800; color: #15803d; }
.verify-desc { font-size: 12.5px; color: #16a34a; line-height: 1.6; }
.verify-email-badge { background: #fff; border: 1px solid #bbf7d0; border-radius: 8px; padding: 7px 16px; font-size: 13px; font-weight: 700; color: #15803d; display: inline-flex; align-items: center; gap: 6px; }

/* ── STEP NAV ── */
.step-nav { display: flex; gap: 10px; margin-top: 22px; }
.btn-back { padding: 11px 22px; background: #f1f5f9; color: #475569; border: none; border-radius: 10px; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.15s; }
.btn-back:hover { background: #e2e8f0; }
.btn-next { flex: 1; padding: 12px; background: linear-gradient(135deg, #2872A1, #08BDDE); color: #fff; border: none; border-radius: 10px; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13.5px; font-weight: 700; cursor: pointer; transition: all 0.2s; box-shadow: 0 4px 14px rgba(40,114,161,0.3); display: flex; align-items: center; justify-content: center; gap: 6px; }
.btn-next:hover { transform: translateY(-1px); box-shadow: 0 6px 20px rgba(40,114,161,0.4); }
.btn-green { background: linear-gradient(135deg, #16a34a, #22c55e); box-shadow: 0 4px 14px rgba(34,197,94,0.35); }
.btn-green:hover { box-shadow: 0 6px 20px rgba(34,197,94,0.45); }

.terms-note { font-size: 11.5px; color: #94a3b8; text-align: center; margin-top: 14px; line-height: 1.6; }
.terms-note a { color: #2872A1; font-weight: 600; text-decoration: none; }
.switch-link { text-align: center; margin-top: 14px; font-size: 13px; color: #64748b; }
.switch-link a { color: #2872A1; font-weight: 700; text-decoration: none; }
.switch-link a:hover { text-decoration: underline; }

.spinner {
  width: 16px; height: 16px; border-radius: 50%;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: #fff;
  animation: spin 0.7s linear infinite;
  flex-shrink: 0;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* ── SUCCESS SCREEN ── */
.success-screen {
  display: flex; flex-direction: column; align-items: center;
  text-align: center; gap: 20px; padding: 20px 0;
}
.success-icon {
  width: 72px; height: 72px; border-radius: 50%;
  background: linear-gradient(135deg, #22c55e, #16a34a);
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 8px 24px rgba(34,197,94,0.35);
}
.success-title {
  font-size: 26px; font-weight: 900; color: #0f172a;
  letter-spacing: -0.02em; margin: 0;
}
.success-desc {
  font-size: 14px; color: #64748b; line-height: 1.7;
  max-width: 360px; margin: 0;
}
.success-desc strong { color: #1e293b; }
.success-email-badge {
  display: inline-flex; align-items: center; gap: 7px;
  background: #f0fdf4; border: 1px solid #bbf7d0;
  border-radius: 99px; padding: 8px 18px;
  font-size: 13px; font-weight: 700; color: #15803d;
}
.success-steps {
  display: flex; flex-direction: column; gap: 12px;
  width: 100%; background: #f8fafc;
  border: 1px solid #f1f5f9; border-radius: 14px; padding: 18px;
  text-align: left;
}
.success-step { display: flex; align-items: flex-start; gap: 12px; }
.sstep-num {
  width: 26px; height: 26px; border-radius: 50%;
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  color: #fff; font-size: 11px; font-weight: 800;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0; margin-top: 1px;
}
.sstep-title { font-size: 13px; font-weight: 700; color: #1e293b; margin: 0 0 2px; }
.sstep-sub   { font-size: 12px; color: #94a3b8; margin: 0; line-height: 1.5; }
.btn-go-login {
  width: 100%; padding: 13px;
  background: linear-gradient(135deg, #2872A1, #08BDDE);
  color: #fff; border: none; border-radius: 10px;
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 14px; font-weight: 700; cursor: pointer;
  text-decoration: none; display: flex;
  align-items: center; justify-content: center; gap: 8px;
  box-shadow: 0 4px 14px rgba(40,114,161,0.3);
  transition: all 0.2s;
}
.btn-go-login:hover { transform: translateY(-1px); box-shadow: 0 6px 20px rgba(40,114,161,0.4); }
</style>