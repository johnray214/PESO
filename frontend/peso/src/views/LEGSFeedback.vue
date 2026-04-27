<template>
  <div class="fb-body">

    <!-- Header -->
    <header class="fb-header">
      <div class="fb-header__seal" aria-hidden="true">
        <img src="@/assets/PESOLOGO.jpg" alt="PESO Logo" @error="handleLogoError" ref="logoImg" />
      </div>
      <p class="fb-header__eyebrow">Republic of the Philippines · City of Santiago</p>
      <h1 class="fb-header__title">Citizen's <em>Feedback</em> Form</h1>
      <p class="fb-header__sub">Public Employment Service Office &nbsp;·&nbsp; WE INTEND TO SERVE YOU BETTER</p>
      <hr class="fb-header__rule" />
    </header>

    <!-- Step Progress -->
    <nav class="fb-steps" aria-label="Form progress">
      <div
        v-for="(label, i) in stepLabels"
        :key="i"
        class="fb-step"
        :class="{ active: currentStep === i + 1, done: currentStep > i + 1 }"
      >
        <div class="fb-step__dot">
          <svg v-if="currentStep > i + 1" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
          <span v-else>{{ i + 1 }}</span>
        </div>
        <span class="fb-step__label">{{ label }}</span>
      </div>
    </nav>

    <!-- Card -->
    <main class="fb-card-wrap">
      <div class="fb-card">

        <!-- ── STEP 1 ── Activity Information -->
        <transition name="fade">
          <div v-if="currentStep === 1" class="fb-panel">
            <h2 class="fb-panel__title">Activity Information</h2>
            <p class="fb-panel__hint">Tell us who you are and which activity you attended.</p>

            <div class="fb-row">
              <div class="fb-field">
                <label class="fb-field__label" for="fn">First Name <span>(Pangalan)</span></label>
                <input class="fb-field__input" :class="{ err: errors.first_name }" type="text" id="fn" v-model="form.first_name" placeholder="Juan" autocomplete="given-name" />
                <p class="fb-field__err" :class="{ show: errors.first_name }">Please enter your first name.</p>
              </div>
              <div class="fb-field">
                <label class="fb-field__label" for="ln">Last Name <span>(Apelyido)</span></label>
                <input class="fb-field__input" :class="{ err: errors.last_name }" type="text" id="ln" v-model="form.last_name" placeholder="dela Cruz" autocomplete="family-name" />
                <p class="fb-field__err" :class="{ show: errors.last_name }">Please enter your last name.</p>
              </div>
            </div>

            <div class="fb-field" style="margin-top:-.2rem">
              <label class="fb-field__label" for="mi">Middle Initial <span>(Gitnang Pangalan)</span></label>
              <input class="fb-field__input" type="text" id="mi" v-model="form.middle_initial" placeholder="M." maxlength="3" style="max-width:80px" />
            </div>

            <div class="fb-field">
              <label class="fb-field__label" for="prog">Program / Activity <span>(Programa o Aktibidad)</span></label>
              <select class="fb-field__select" :class="{ err: errors.program }" id="prog" v-model="form.program">
                <option value="">— Select Activity —</option>
                <option value="Career Guidance for Grade 10">Career Guidance for Grade 10</option>
                <option value="Career Exploration for Grade 12">Career Exploration for Grade 12</option>
                <option value="LEGS">LEGS</option>
                <option value="Pre Employment Orientation">Pre Employment Orientation</option>
              </select>
              <p class="fb-field__err" :class="{ show: errors.program }">Please select the program or activity.</p>
            </div>

            <div class="fb-field">
              <label class="fb-field__label" for="venue">Venue / School <span>(Lugar o Paaralan)</span></label>
              <input class="fb-field__input" :class="{ err: errors.venue }" type="text" id="venue" v-model="form.venue" placeholder="e.g. City Hall Auditorium" />
              <p class="fb-field__err" :class="{ show: errors.venue }">Please enter the venue.</p>
            </div>

            <div class="fb-field">
              <label class="fb-field__label" for="adate">Date of Activity <span>(Petsa ng Activity)</span></label>
              <input class="fb-field__input" type="date" id="adate" v-model="form.activity_date" />
            </div>

            <div class="fb-cta">
              <span class="fb-cta__info">Step 1 of 4</span>
              <button class="fb-btn fb-btn--next" type="button" @click="goToStep2">
                Next — Ratings
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
              </button>
            </div>
          </div>
        </transition>

        <!-- ── STEP 2 ── Ratings -->
        <transition name="fade">
          <div v-if="currentStep === 2" class="fb-panel">
            <h2 class="fb-panel__title">Areas</h2>
            <p class="fb-panel__hint">Rate the following: 1 = Very Poor &nbsp;·&nbsp; 2 = Poor &nbsp;·&nbsp; 3 = Satisfactory &nbsp;·&nbsp; 4 = Good &nbsp;·&nbsp; 5 = Excellent</p>

            <div class="fb-rating-section">
              <p class="fb-rating-section__title">Areas</p>

              <div class="fb-rating-row">
                <div class="fb-rating-row__label">Program Content<small>Nilalaman ng Programa</small></div>
                <div class="fb-stars">
                  <button
                    v-for="n in 5" :key="n"
                    class="fb-star-btn" type="button"
                    :class="{ sel: ratings.program_content >= n }"
                    @click="ratings.program_content = n"
                  >{{ n }}</button>
                </div>
              </div>

              <div class="fb-rating-row">
                <div class="fb-rating-row__label">Level of Interaction<small>Pakikipag-ugnayan</small></div>
                <div class="fb-stars">
                  <button
                    v-for="n in 5" :key="n"
                    class="fb-star-btn" type="button"
                    :class="{ sel: ratings.interaction >= n }"
                    @click="ratings.interaction = n"
                  >{{ n }}</button>
                </div>
              </div>

              <div class="fb-rating-row">
                <div class="fb-rating-row__label">Mastery of Topic<small>Kasanayan sa paksa</small></div>
                <div class="fb-stars">
                  <button
                    v-for="n in 5" :key="n"
                    class="fb-star-btn" type="button"
                    :class="{ sel: ratings.mastery >= n }"
                    @click="ratings.mastery = n"
                  >{{ n }}</button>
                </div>
              </div>
            </div>

            <div class="fb-overall-row">
              <div class="fb-overall-row__label">
                Overall Activity Rating
                <small>Sa pangkalahatan, ano ang iyong rating sa activity</small>
              </div>
              <div class="fb-stars">
                <button
                  v-for="n in 5" :key="n"
                  class="fb-star-btn" type="button"
                  :class="{ sel: ratings.overall >= n }"
                  @click="ratings.overall = n"
                >{{ n }}</button>
              </div>
            </div>

            <!-- Rating incomplete notice -->
            <p v-if="ratingTouched && !allRatingsFilled" class="fb-rating-warn">
              ⚠ Please rate all areas before continuing.
            </p>

            <div class="fb-cta">
              <button class="fb-btn fb-btn--back" type="button" @click="currentStep = 1">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M11 6l-6 6 6 6"/></svg>
                Back
              </button>
              <div style="display:flex;align-items:center;gap:.75rem;flex-wrap:wrap">
                <span class="fb-cta__info">Step 2 of 4</span>
                <button
                  class="fb-btn fb-btn--next"
                  :class="{ disabled: !allRatingsFilled }"
                  :disabled="!allRatingsFilled"
                  type="button"
                  @click="handleStep2Next"
                >
                  Next — Remarks
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
                </button>
              </div>
            </div>
          </div>
        </transition>

        <!-- ── STEP 3 ── Remarks + Submit -->
        <transition name="fade">
          <div v-if="currentStep === 3" class="fb-panel">
            <h2 class="fb-panel__title">Suggestions &amp; Remarks</h2>
            <p class="fb-panel__hint">Share any suggestions or recommendations to help us improve.</p>

            <div class="fb-field">
              <label class="fb-field__label" for="remarks">Suggestion / Recommendation <span>(Mungkahi o Rekomendasyon)</span></label>
              <textarea class="fb-field__textarea" id="remarks" v-model="form.remarks" placeholder="Write your suggestions here…" rows="5"></textarea>
            </div>

            <div class="fb-cta">
              <button class="fb-btn fb-btn--back" type="button" @click="currentStep = 2">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 12H5M11 6l-6 6 6 6"/></svg>
                Back
              </button>
              <div style="display:flex;align-items:center;gap:.75rem;flex-wrap:wrap">
                <span class="fb-cta__info">Step 3 of 4</span>
                <button class="fb-btn fb-btn--next" :class="{ disabled: submitting }" :disabled="submitting" type="button" @click="submitFeedback">
                  <span v-if="submitting">Submitting…</span>
                  <template v-else>
                    Submit &amp; Continue
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg>
                  </template>
                </button>
              </div>
            </div>

            <p v-if="submitError" class="fb-submit-error">{{ submitError }}</p>
          </div>
        </transition>

        <!-- ── STEP 4 ── Thank You + Certificate -->
        <transition name="fade">
          <div v-if="currentStep === 4" class="fb-panel">
            <div class="fb-thankyou-head">
              <div class="fb-thankyou-head__icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
              </div>
              <h2 class="fb-thankyou-head__title">Thank You!</h2>
              <p class="fb-thankyou-head__sub">Your feedback has been submitted successfully.</p>
            </div>

            <hr class="fb-divider" />

            <h3 class="fb-panel__title">Your Certificate of Participation</h3>
            <p class="fb-panel__hint">Your certificate is ready. Click below to download using the official template.</p>

            <!-- Certificate Preview -->
            <div class="fb-cert-preview">
              <div class="fb-cert-preview__inner">
                <p class="fb-cert-preview__eyebrow">Republic of the Philippines</p>
                <p class="fb-cert-preview__org">City of Santiago<br />Public Employment Service Office</p>
                <p class="fb-cert-preview__addr">ITC Four Lanes Malvar, Santiago City</p>
                <p class="fb-cert-preview__awards">Awards this</p>
                <p class="fb-cert-preview__title">Certificate of Participation</p>
                <p class="fb-cert-preview__to">to</p>
                <p class="fb-cert-preview__name">{{ fullName }}</p>
                <p class="fb-cert-preview__body">
                  for actively attending the<br />
                  <strong>CAREER DEVELOPMENT SUPPORT PROGRAM</strong><br />
                  ({{ form.program }}) Conducted by the PESO Office<br />
                  on {{ formattedDate }} at {{ form.venue }}.
                </p>
                <p class="fb-cert-preview__body" style="margin-top:.5rem">
                  Given this {{ certDay }} day of {{ certMonth }}, {{ certYear }}
                  Malvar, Santiago City, Philippines
                </p>
                <div class="fb-cert-preview__sigs">
                  <div class="fb-cert-preview__sig">
                    <div class="fb-cert-preview__sig-line"></div>
                    <p class="fb-cert-preview__sig-name">FEDENCIO R. DASALLA JR.</p>
                    <p class="fb-cert-preview__sig-title">CDSP Focal</p>
                  </div>
                  <div class="fb-cert-preview__sig">
                    <div class="fb-cert-preview__sig-line"></div>
                    <p class="fb-cert-preview__sig-name">ATTY. NIKKI JANE S. ISLA</p>
                    <p class="fb-cert-preview__sig-title">OIC, PESO Manager</p>
                  </div>
                </div>
              </div>
            </div>

            <button class="fb-btn-cert-dl" type="button" @click="downloadCert">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Download Certificate (PDF)
            </button>

            <div class="fb-cta" style="margin-top:1.5rem">
              <span class="fb-cta__info">Step 4 of 4 &nbsp;·&nbsp; Thank you!</span>
              <button class="fb-btn fb-btn--back" type="button" @click="resetForm">Submit another response</button>
            </div>
          </div>
        </transition>

      </div>
    </main>

    <footer class="fb-footer">
      Public Employment Service Office &nbsp;·&nbsp; Landline: (078) 305-2758
    </footer>
  </div>
</template>

<script>
import api from '@/services/api'

const MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December']

function ordinal(n) {
  const s = ['th','st','nd','rd']
  const v = n % 100
  return n + (s[(v - 20) % 10] || s[v] || s[0])
}

export default {
  name: 'LEGSFeedback',

  data() {
    return {
      currentStep: 1,
      stepLabels: ['Details', 'Ratings', 'Remarks', 'Certificate'],

      form: {
        first_name:    '',
        last_name:     '',
        middle_initial:'',
        program:       'LEGS',
        venue:         '',
        activity_date: '',
        remarks:       '',
      },

      ratings: {
        program_content: 0,
        interaction:     0,
        mastery:         0,
        overall:         0,
      },

      errors: {},
      ratingTouched: false,
      submitting: false,
      submitError: '',

      // snapshot taken right after successful submit for the certificate
      snapshot: null,
    }
  },

  computed: {
    allRatingsFilled() {
      return (
        this.ratings.program_content > 0 &&
        this.ratings.interaction     > 0 &&
        this.ratings.mastery         > 0 &&
        this.ratings.overall         > 0
      )
    },

    fullName() {
      const mi = this.form.middle_initial ? ` ${this.form.middle_initial}` : ''
      return `${this.form.first_name}${mi} ${this.form.last_name}`.trim()
    },

    formattedDate() {
      if (!this.form.activity_date) return '—'
      const [y, m, d] = this.form.activity_date.split('-')
      return `${MONTHS[parseInt(m, 10) - 1]} ${parseInt(d, 10)}, ${y}`
    },

    certDay()   { return ordinal(new Date().getDate()) },
    certMonth() { return MONTHS[new Date().getMonth()] },
    certYear()  { return new Date().getFullYear() },
  },

  methods: {
    handleLogoError(e) {
      e.target.style.display = 'none'
    },

    /* ── Step 1 → 2 ── */
    goToStep2() {
      this.errors = {}
      let hasError = false

      if (!this.form.first_name.trim()) { this.errors.first_name = true; hasError = true }
      if (!this.form.last_name.trim())  { this.errors.last_name  = true; hasError = true }
      if (!this.form.program)           { this.errors.program    = true; hasError = true }
      if (!this.form.venue.trim())      { this.errors.venue      = true; hasError = true }

      if (hasError) return
      this.currentStep = 2
    },

    /* ── Step 2 → 3 — guarded by allRatingsFilled ── */
    handleStep2Next() {
      this.ratingTouched = true
      if (!this.allRatingsFilled) return
      this.currentStep = 3
    },

    /* ── Submit ── */
    async submitFeedback() {
      this.submitting  = true
      this.submitError = ''

      try {
        const payload = {
          first_name:              this.form.first_name.trim(),
          last_name:               this.form.last_name.trim(),
          middle_initial:          this.form.middle_initial.trim() || null,
          program:                 this.form.program,
          venue:                   this.form.venue.trim() || null,
          activity_date:           this.form.activity_date || null,
          rating_program_content:  this.ratings.program_content,
          rating_interaction:      this.ratings.interaction,
          rating_mastery:          this.ratings.mastery,
          rating_overall:          this.ratings.overall,
          remarks:                 this.form.remarks.trim() || null,
        }

        await api.post('/legs-feedback', payload)

        // Keep snapshot for certificate
        this.snapshot = { ...this.form }
        this.currentStep = 4
      } catch (err) {
        const msg = err?.response?.data?.message || 'Submission failed. Please try again.'
        this.submitError = msg
      } finally {
        this.submitting = false
      }
    },

    /* ── Certificate download (print-to-pdf via browser) ── */
    downloadCert() {
      window.print()
    },

    /* ── Reset for another response ── */
    resetForm() {
      this.currentStep    = 1
      this.ratingTouched  = false
      this.submitError    = ''
      this.snapshot       = null
      this.errors         = {}
      this.form = {
        first_name:    '',
        last_name:     '',
        middle_initial:'',
        program:       'LEGS',
        venue:         '',
        activity_date: '',
        remarks:       '',
      }
      this.ratings = { program_content: 0, interaction: 0, mastery: 0, overall: 0 }
    },
  },
}
</script>

<style scoped>
/* ── Reset & Root Variables ── */
*,*::before,*::after { box-sizing: border-box; }
:root {
  --ink:    #0f1923;
  --paper:  #f4f7fb;
  --cream:  #eaf0f8;
  --navy:   #1a3a5c;
  --navy2:  #2a5285;
  --navydk: #0e2540;
  --line:   #d0dbe8;
  --muted:  #7a90a8;
  --white:  #ffffff;
  --green:  #1a7a4a;
}

/* ── Page ── */
.fb-body {
  font-family: 'DM Sans', 'Inter', sans-serif;
  color: var(--ink);
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 2rem 1rem 4rem;
  background-color: var(--paper);
  background-image:
    radial-gradient(ellipse at 75% 5%, #dceaf8 0%, transparent 50%),
    radial-gradient(ellipse at 10% 95%, #e8f0fa 0%, transparent 45%),
    repeating-linear-gradient(0deg, transparent, transparent 27px, rgba(160,185,215,.18) 27px, rgba(160,185,215,.18) 28px);
}

/* ── Header ── */
.fb-header {
  text-align: center;
  max-width: 560px;
  width: 100%;
  margin-bottom: 2rem;
  padding-top: 1rem;
  animation: fadeUp .5s ease both;
}
.fb-header__seal {
  width: 80px; height: 80px;
  border-radius: 50%;
  border: 2px solid var(--navy2);
  display: inline-flex; align-items: center; justify-content: center;
  margin-bottom: .9rem;
  background: var(--white);
  box-shadow: 0 0 0 4px var(--cream), 0 0 0 5px var(--line);
  overflow: hidden;
}
.fb-header__seal img {
  width: 100%; height: 100%; object-fit: cover; border-radius: 50%;
}
.fb-header__eyebrow {
  font-size: .66rem; font-weight: 500; letter-spacing: .18em;
  text-transform: uppercase; color: var(--muted); margin-bottom: .2rem;
}
.fb-header__title {
  font-family: 'Libre Baskerville', Georgia, serif;
  font-size: clamp(1.4rem, 5vw, 1.9rem);
  font-weight: 700; line-height: 1.15; margin-bottom: .3rem;
}
.fb-header__title em { font-style: italic; color: var(--navy); }
.fb-header__sub { font-size: .78rem; font-weight: 300; color: var(--muted); }
.fb-header__rule {
  margin: 1rem auto 0; width: 40px; height: 2px;
  background: var(--navy); border: none;
}

/* ── Steps ── */
.fb-steps {
  display: flex; align-items: flex-start;
  max-width: 560px; width: 100%; margin-bottom: 1.8rem;
  animation: fadeUp .5s ease .08s both;
}
.fb-step {
  display: flex; flex-direction: column; align-items: center;
  gap: .3rem; flex: 1; position: relative;
}
.fb-step:not(:last-child)::after {
  content: '';
  position: absolute; top: 13px;
  left: calc(50% + 14px); right: calc(-50% + 14px);
  height: 1px; background: var(--line); transition: background .4s;
}
.fb-step.done:not(:last-child)::after { background: var(--navy); }
.fb-step__dot {
  width: 26px; height: 26px; border-radius: 50%;
  border: 2px solid var(--line); background: var(--paper);
  display: flex; align-items: center; justify-content: center;
  font-size: .68rem; font-weight: 600; color: var(--muted);
  transition: all .25s; z-index: 1;
}
.fb-step__dot svg { width: 13px; height: 13px; }
.fb-step.active .fb-step__dot,
.fb-step.done   .fb-step__dot {
  background: var(--navy); border-color: var(--navy); color: var(--white);
  box-shadow: 0 0 0 3px rgba(26,58,92,.14);
}
.fb-step__label {
  font-size: .6rem; font-weight: 500; letter-spacing: .07em;
  text-transform: uppercase; color: var(--muted);
}
.fb-step.active .fb-step__label,
.fb-step.done   .fb-step__label { color: var(--navy); }

/* ── Card ── */
.fb-card-wrap { max-width: 560px; width: 100%; animation: fadeUp .5s ease .16s both; }
.fb-card {
  background: var(--white); border: 1px solid var(--line); border-radius: 6px;
  padding: 1.8rem 1.6rem;
  box-shadow: 0 2px 16px rgba(26,58,92,.07), 0 1px 3px rgba(26,58,92,.05);
  position: relative; overflow: hidden;
}
.fb-card::before {
  content: '';
  position: absolute; top: 0; left: 0; right: 0; height: 3px;
  background: linear-gradient(90deg, var(--navy), var(--navy2));
  border-radius: 6px 6px 0 0;
}

/* ── Panel ── */
.fb-panel__title {
  font-family: 'Libre Baskerville', Georgia, serif;
  font-size: .95rem; font-weight: 700; margin-bottom: .2rem;
}
.fb-panel__hint { font-size: .73rem; color: var(--muted); margin-bottom: 1.5rem; }

/* ── Fields ── */
.fb-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
@media (max-width: 400px) { .fb-row { grid-template-columns: 1fr; } }

.fb-field { margin-bottom: 1.3rem; }
.fb-field__label {
  display: block; font-size: .67rem; font-weight: 600;
  letter-spacing: .1em; text-transform: uppercase;
  color: var(--muted); margin-bottom: .45rem;
}
.fb-field__label span {
  font-style: italic; font-weight: 300; letter-spacing: 0;
  text-transform: none; font-size: .66rem; color: #b0bfce; margin-left: .3rem;
}
.fb-field__input,
.fb-field__select {
  width: 100%; background: transparent; border: none;
  border-bottom: 1.5px solid var(--line);
  padding: .5rem .1rem;
  font-family: inherit; font-size: .93rem; color: var(--ink);
  outline: none; transition: border-color .2s; border-radius: 0;
  appearance: none; -webkit-appearance: none;
}
.fb-field__input::placeholder { color: #c0cdd9; font-weight: 300; }
.fb-field__input:focus,
.fb-field__select:focus { border-bottom-color: var(--navy); }
.fb-field__input.err,
.fb-field__select.err { border-bottom-color: #c0392b; }
.fb-field__err { font-size: .67rem; color: #c0392b; margin-top: .25rem; display: none; }
.fb-field__err.show { display: block; }
.fb-field__textarea {
  width: 100%; background: transparent;
  border: 1.5px solid var(--line); border-radius: 4px;
  padding: .65rem .75rem;
  font-family: inherit; font-size: .88rem; color: var(--ink);
  outline: none; transition: border-color .2s; resize: vertical; min-height: 100px;
}
.fb-field__textarea:focus { border-color: var(--navy); }
.fb-field__textarea::placeholder { color: #c0cdd9; font-weight: 300; }

/* ── Ratings ── */
.fb-rating-section { margin-bottom: 1.5rem; }
.fb-rating-section__title {
  font-size: .72rem; font-weight: 700; letter-spacing: .1em;
  text-transform: uppercase; color: var(--navy);
  margin-bottom: .9rem; display: flex; align-items: center; gap: .5rem;
}
.fb-rating-section__title::after {
  content: ''; flex: 1; height: 1px; background: var(--cream);
}
.fb-rating-row {
  display: grid; grid-template-columns: 1fr auto;
  align-items: center; gap: .5rem; margin-bottom: .75rem;
}
.fb-rating-row__label { font-size: .8rem; color: var(--ink); }
.fb-rating-row__label small { display: block; font-size: .66rem; color: var(--muted); font-style: italic; }
.fb-stars { display: flex; gap: .2rem; }
.fb-star-btn {
  width: 30px; height: 30px; border-radius: 2px;
  border: 1.5px solid var(--line); background: transparent;
  cursor: pointer; font-size: .72rem; font-weight: 700; color: var(--muted);
  transition: all .15s; display: flex; align-items: center; justify-content: center;
}
.fb-star-btn:hover { border-color: var(--navy2); background: rgba(42,82,133,.08); color: var(--navy); }
.fb-star-btn.sel   { background: var(--navy); border-color: var(--navy); color: var(--white); }
.fb-overall-row {
  background: var(--paper); border: 1px solid var(--line); border-radius: 4px;
  padding: .9rem 1rem;
  display: flex; align-items: center; justify-content: space-between;
  gap: .75rem; flex-wrap: wrap; margin-top: .5rem;
}
.fb-overall-row__label { font-size: .82rem; font-weight: 600; color: var(--ink); }
.fb-overall-row__label small {
  display: block; font-size: .66rem; color: var(--muted); font-style: italic; font-weight: 300;
}

.fb-rating-warn {
  font-size: .72rem; color: #c0392b;
  margin: .6rem 0 0;
  padding: .4rem .6rem;
  background: #fef2f2; border: 1px solid #fca5a5; border-radius: 4px;
}

/* ── CTA row ── */
.fb-cta {
  margin-top: 1.8rem;
  display: flex; align-items: center; justify-content: space-between;
  gap: .75rem; flex-wrap: wrap;
}
.fb-cta__info { font-size: .7rem; color: var(--muted); }

/* ── Buttons ── */
.fb-btn {
  display: inline-flex; align-items: center; gap: .45rem;
  font-family: inherit; font-size: .78rem; font-weight: 600;
  letter-spacing: .07em; text-transform: uppercase;
  border: none; padding: .7rem 1.4rem; cursor: pointer;
  border-radius: 3px; transition: all .15s; white-space: nowrap;
}
.fb-btn svg { width: 15px; height: 15px; }
.fb-btn--back {
  background: transparent; border: 1.5px solid var(--line); color: var(--muted);
}
.fb-btn--back:hover { border-color: var(--navy); color: var(--navy); }
.fb-btn--next {
  background: var(--navy); color: var(--white);
  box-shadow: 3px 3px 0 var(--navydk);
}
.fb-btn--next:hover:not(.disabled) {
  background: #153151; transform: translateY(-1px); box-shadow: 3px 4px 0 var(--navydk);
}
.fb-btn--next:active:not(.disabled) { transform: translateY(1px); box-shadow: 1px 1px 0 var(--navydk); }
.fb-btn--next.disabled,
.fb-btn--next:disabled {
  opacity: .45; cursor: not-allowed; transform: none;
  box-shadow: 3px 3px 0 var(--navydk);
}

.fb-submit-error {
  font-size: .73rem; color: #991b1b; margin-top: .75rem;
  padding: .5rem .75rem; background: #fef2f2; border: 1px solid #fca5a5; border-radius: 4px;
}

/* ── Divider ── */
.fb-divider { border: none; border-top: 1px dashed var(--line); margin: 1.4rem 0; }

/* ── Thank-you ── */
.fb-thankyou-head { text-align: center; padding: .5rem 0 1rem; }
.fb-thankyou-head__icon {
  width: 56px; height: 56px; border-radius: 50%; background: var(--green);
  display: inline-flex; align-items: center; justify-content: center;
  margin-bottom: .9rem; box-shadow: 0 0 0 6px rgba(26,122,74,.12);
}
.fb-thankyou-head__icon svg { width: 26px; height: 26px; color: var(--white); }
.fb-thankyou-head__title {
  font-family: 'Libre Baskerville', Georgia, serif;
  font-size: 1.4rem; font-weight: 700; margin-bottom: .3rem;
}
.fb-thankyou-head__sub { font-size: .78rem; color: var(--muted); }

/* ── Certificate Preview ── */
.fb-cert-preview {
  margin: 1.2rem 0; border: 1px solid var(--line);
  border-radius: 4px; padding: .5rem; background: var(--cream);
}
.fb-cert-preview__inner {
  border: 2px solid var(--navy); border-radius: 3px;
  padding: 2rem 1.5rem; text-align: center; background: var(--white); position: relative;
}
.fb-cert-preview__inner::before {
  content: ''; position: absolute; inset: 6px;
  border: 1px solid var(--line); border-radius: 2px; pointer-events: none;
}
.fb-cert-preview__eyebrow { font-size: .6rem; letter-spacing: .15em; text-transform: uppercase; color: var(--muted); margin-bottom: .15rem; margin-top: .5rem; }
.fb-cert-preview__org     { font-size: .7rem; font-weight: 700; letter-spacing: .08em; text-transform: uppercase; color: var(--navy); margin-bottom: .15rem; }
.fb-cert-preview__addr    { font-size: .58rem; color: var(--muted); margin-bottom: .8rem; }
.fb-cert-preview__awards  { font-size: .72rem; color: var(--ink); margin-bottom: .3rem; }
.fb-cert-preview__title   { font-family: 'Libre Baskerville', Georgia, serif; font-size: 1.4rem; font-weight: 700; color: var(--ink); margin-bottom: .6rem; letter-spacing: .03em; }
.fb-cert-preview__to      { font-size: .65rem; color: var(--muted); margin-bottom: .1rem; }
.fb-cert-preview__name    { font-family: 'Libre Baskerville', Georgia, serif; font-size: 1.05rem; font-weight: 700; color: var(--navy); border-bottom: 1.5px solid var(--navy); display: inline-block; min-width: 200px; padding-bottom: .15rem; margin-bottom: .8rem; }
.fb-cert-preview__body    { font-size: .72rem; color: var(--ink); line-height: 1.8; margin-bottom: .4rem; }
.fb-cert-preview__body strong { font-weight: 700; }
.fb-cert-preview__sigs    { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-top: 1.2rem; }
.fb-cert-preview__sig     { text-align: center; }
.fb-cert-preview__sig-line{ border-top: 1px solid var(--ink); margin-bottom: .25rem; width: 80%; margin-left: auto; margin-right: auto; }
.fb-cert-preview__sig-name{ font-size: .62rem; font-weight: 700; color: var(--ink); }
.fb-cert-preview__sig-title{ font-size: .56rem; color: var(--muted); }

/* ── Cert download button ── */
.fb-btn-cert-dl {
  display: flex; align-items: center; gap: .6rem;
  width: 100%; justify-content: center;
  font-family: inherit; font-size: .82rem; font-weight: 600;
  letter-spacing: .06em; text-transform: uppercase;
  border: none; background: var(--navy); color: var(--white);
  padding: .9rem 1.5rem; border-radius: 3px; cursor: pointer;
  margin-top: .75rem; box-shadow: 3px 3px 0 var(--navydk); transition: all .15s;
}
.fb-btn-cert-dl svg { width: 16px; height: 16px; }
.fb-btn-cert-dl:hover { background: #153151; transform: translateY(-1px); box-shadow: 3px 4px 0 var(--navydk); }
.fb-btn-cert-dl:active{ transform: translateY(1px); box-shadow: 1px 1px 0 var(--navydk); }

/* ── Footer ── */
.fb-footer {
  max-width: 560px; width: 100%; margin-top: 1.4rem;
  text-align: center; font-size: .66rem; color: var(--muted);
  animation: fadeUp .5s ease .24s both;
}

/* ── Transitions ── */
.fade-enter-active, .fade-leave-active { transition: opacity .25s, transform .25s; }
.fade-enter-from { opacity: 0; transform: translateY(8px); }
.fade-leave-to   { opacity: 0; transform: translateY(-8px); }

/* ── Animations ── */
@keyframes fadeUp {
  from { opacity: 0; transform: translateY(14px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* ── Print styles for certificate ── */
@media print {
  .fb-header, .fb-steps, .fb-cta, .fb-panel__title, .fb-panel__hint,
  .fb-btn-cert-dl, .fb-footer, .fb-thankyou-head, .fb-divider { display: none !important; }
  .fb-body { background: none; padding: 0; }
  .fb-card  { box-shadow: none; border: none; }
  .fb-cert-preview { border: none; background: none; margin: 0; }
}
</style>
