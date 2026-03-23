const fs = require('fs');
const path = require('path');
const viewsDir = 'd:/Practice/PESO/frontend/peso/src/views';

const forgot = fs.readFileSync(path.join(viewsDir, 'EmployerForgot.vue'), 'utf8');
const reset = fs.readFileSync(path.join(viewsDir, 'EmployerReset.vue'), 'utf8');

const createVariant = (base, targetPort, targetRoute) => {
    let content = base;
    content = content.replace(/Employer Portal/g, targetPort + ' Portal');
    content = content.replace(/\/employer\/login/g, targetRoute + '/login');
    content = content.replace(/\/employer\//g, targetRoute + '/');
    content = content.replace(/EmployerForgot/g, targetPort + 'Forgot');
    content = content.replace(/EmployerReset/g, targetPort + 'Reset');
    return content;
};

fs.writeFileSync(path.join(viewsDir, 'AdminForgot.vue'), createVariant(forgot, 'Admin', '/admin'));
fs.writeFileSync(path.join(viewsDir, 'AdminReset.vue'), createVariant(reset, 'Admin', '/admin'));
fs.writeFileSync(path.join(viewsDir, 'JobseekerForgot.vue'), createVariant(forgot, 'Jobseeker', '/jobseeker'));
fs.writeFileSync(path.join(viewsDir, 'JobseekerReset.vue'), createVariant(reset, 'Jobseeker', '/jobseeker'));

console.log('Done!');
