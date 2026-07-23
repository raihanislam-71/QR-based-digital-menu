importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

// আপনার Firebase Console থেকে Web App-এর কনফিগারেশন ডাটা এখানে বসাবেন
firebase.initializeApp({
  apiKey: 'AIzaSyAN9fyWHtMuGv9fyOCYi_ytkJSBftlJj_A',
  appId: '1:76147858957:web:63285b9ee2a4b8e218ff44',
  messagingSenderId: '76147858957',
  projectId: 'digital-manu-fce86',
  authDomain: 'digital-manu-fce86.firebaseapp.com',
  storageBucket: 'digital-manu-fce86.firebasestorage.app',
});

const messaging = firebase.messaging();

// ব্যাকগ্রাউন্ড নোটিফিকেশন হ্যান্ডল করার জন্য
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});