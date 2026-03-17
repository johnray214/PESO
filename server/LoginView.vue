<template>
  <div class="login-wrapper">
    <div class="login-card">
      <div class="logo-section">
        <img :src="pesoLogo" alt="PESO" class="logo" />
        <h1 class="title">Employer Portal</h1>
        <p class="subtitle">Sign in to manage your job postings</p>
      </div>
      <form @submit.prevent="handleLogin" class="login-form">
        <div class="form-group">
          <label class="form-label">Email</label>
          <input v-model="form.email" type="email" class="form-input" placeholder="employer@company.com" required/>
        </div>
        <div class="form-group">
          <label class="form-label">Password</label>
          <input v-model="form.password" type="password" class="form-input" placeholder="Enter your password" required/>
        </div>
        <div class="form-options">
          <label class="checkbox-label">
            <input type="checkbox" v-model="form.remember"/>
            Remember me
          </label>
          <a href="#" class="link-text">Forgot password?</a>
        </div>
        <button type="submit" class="btn-login">
          Sign In
        </button>
      </form>
      <p class="register-text">
        Don't have an account?
        <router-link to="/employer/register" class="link-text">Register here</router-link>
      </p>
    </div>
  </div>
</template>

<script>
import api from '@/services/api'
import pesoLogo from '@/assets/PESOLOGO.jpg'

export default {
  name: 'EmployerLogin',
  data() {
    return {
      pesoLogo,
      form: {
        email: 'hr@accenture.ph',
        password: 'password123',
        remember: false,
      },
    }
  },
  methods: {
    async handleLogin() {
      try {
        const response = await api.post('/employer/login', {
          email: this.form.email,
          password: this.form.password,
        })
        
        localStorage.setItem('employer_token', response.data.token)
        localStorage.setItem('employer_data', JSON.stringify(response.data.employer))
        
        this.$router.push('/employer/dashboard')
      } catch (error) {
        console.error('Login error:', error)
        alert('Invalid credentials')
      }
    },
  },
}
</script>

<style scoped>
.login-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  font-family: 'Plus Jakarta Sans', sans-serif;
  padding: 20px;
}

.login-card {
  width: 100%;
  max-width: 420px;
  background: #fff;
  border-radius: 20px;
  padding: 40px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.logo-section {
  text-align: center;
  margin-bottom: 32px;
}

.logo {
  width: 80px;
  height: 80px;
  object-fit: cover;
  border-radius: 16px;
  margin-bottom: 16px;
}

.title {
  font-size: 24px;
  font-weight: 800;
  color: #1e293b;
  margin-bottom: 6px;
}

.subtitle {
  font-size: 13px;
  color: #94a3b8;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 12px;
  font-weight: 700;
  color: #1e293b;
}

.form-input {
  padding: 12px 14px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 14px;
  font-family: inherit;
  color: #1e293b;
  transition: all 0.15s;
}

.form-input:focus {
  outline: none;
  border-color: #2563eb;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}

.form-options {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #64748b;
  cursor: pointer;
}

.link-text {
  font-size: 12px;
  color: #2563eb;
  font-weight: 600;
  text-decoration: none;
}

.link-text:hover {
  text-decoration: underline;
}

.btn-login {
  padding: 12px;
  background: #2563eb;
  color: #fff;
  border: none;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  font-family: inherit;
  transition: background 0.15s;
  margin-top: 8px;
}

.btn-login:hover {
  background: #1d4ed8;
}

.register-text {
  text-align: center;
  font-size: 12px;
  color: #64748b;
  margin-top: 24px;
}
</style>
