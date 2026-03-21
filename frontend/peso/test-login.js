async function testLogin() {
  try {
    const res = await fetch('http://127.0.0.1:8000/api/employer/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ email: 'hr@nexustech.ph', password: 'password123' })
    });
    const data = await res.json();
    console.log("LOGIN RESPONSE:");
    console.log(JSON.stringify(data, null, 2));
  } catch (err) {
    console.error("ERROR:", err.message);
  }
}
testLogin();
