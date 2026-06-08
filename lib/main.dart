<div key={f} style={{ padding:"8px 12px", borderRadius:8, background:C.purplePale, color:C.purple, fontSize:13, marginBottom:6, textAlign:"center", fontWeight:600 }}>{f}</div>
          ))}
        </Card>
      </div>
    </div>
  );
}

// ─── Root ─────────────────────────────────────────────────────────────────────
export default function App() {
  const [screen, setScreen] = useState("splash");
  const [phone,  setPhone]  = useState("");
  const [otp,    setOtp]    = useState("");

  return (
    <div style={{ maxWidth:430, margin:"0 auto", minHeight:"100dvh", position:"relative", overflow:"hidden" }}>
      <style>{styles}</style>
      {screen==="splash"       && <Splash  onNext={() => setScreen("landing")} />}
      {screen==="landing"      && <Landing onCustomer={() => setScreen("phone")} onBusiness={() => setScreen("business")} />}
      {screen==="phone"        && <PhoneScreen onOTPSent={(p,o) => { setPhone(p); setOtp(o); setScreen("otp"); }} onBack={() => setScreen("landing")} />}
      {screen==="otp"          && <OTPScreen phone={phone} otp={otp} onVerified={() => setScreen("customerDash")} onBack={() => setScreen("phone")} />}
      {screen==="customerDash" && <CustomerDashboard phone={phone} onLogout={() => setScreen("landing")} />}
      {screen==="business"     && <BusinessPortal onLogout={() => setScreen("landing")} />}
    </div>
  );
}
