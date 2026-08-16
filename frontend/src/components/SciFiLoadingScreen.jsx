import { useEffect, useRef, useState } from "react";

export function SciFiLoadingScreen({ onFinished, minDuration = 2200 }) {
  const canvasRef = useRef(null);
  const [statusText, setStatusText] = useState("DECRYPTING ATTENDANCE PROTOCOL");
  const [dots, setDots] = useState("....");
  const [fading, setFading] = useState(false);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");

    let animationFrameId;
    function resize() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    }
    resize();
    window.addEventListener("resize", resize);

    const chars = "0123456789ABCDEFΣΩΨλπΔSWEGEOFENCEHAIVERSINE0x7F";
    const fontSize = 13;
    let columns = Math.floor(canvas.width / fontSize);
    let drops = Array(columns).fill(1).map(() => Math.floor(Math.random() * -40));

    function drawMatrix() {
      ctx.fillStyle = "rgba(0, 0, 0, 0.12)";
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      ctx.font = `${fontSize}px 'Share Tech Mono', monospace`;

      for (let i = 0; i < drops.length; i++) {
        const text = chars[Math.floor(Math.random() * chars.length)];
        const x = i * fontSize;
        const y = drops[i] * fontSize;

        if (Math.random() > 0.85) {
          ctx.fillStyle = "#ffffff";
        } else if (Math.random() > 0.5) {
          ctx.fillStyle = "#00E6FF";
        } else {
          ctx.fillStyle = "#00FF88";
        }

        ctx.fillText(text, x, y);

        if (y > canvas.height && Math.random() > 0.975) {
          drops[i] = 0;
        }
        drops[i]++;
      }
    }

    const interval = setInterval(drawMatrix, 45);

    return () => {
      clearInterval(interval);
      window.removeEventListener("resize", resize);
    };
  }, []);

  useEffect(() => {
    let count = 0;
    const interval = setInterval(() => {
      count = (count + 1) % 5;
      setDots(".".repeat(count));
    }, 320);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const phrases = [
      "DECRYPTING ATTENDANCE PROTOCOL",
      "CALIBRATING HAVERSINE GPS MATRIX",
      "BINDING HARDWARE DEVICE LOCK",
      "INITIALIZING SECURE SESSION",
    ];

    let pIdx = 0;
    const interval = setInterval(() => {
      pIdx = (pIdx + 1) % phrases.length;
      setStatusText(phrases[pIdx]);
    }, 1200);

    const fadeTimer = setTimeout(() => {
      setFading(true);
    }, minDuration - 400);

    const finishTimer = setTimeout(() => {
      if (onFinished) onFinished();
    }, minDuration);

    return () => {
      clearInterval(interval);
      clearTimeout(fadeTimer);
      clearTimeout(finishTimer);
    };
  }, [minDuration, onFinished]);

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        backgroundColor: "#000000",
        color: "#ffffff",
        zIndex: 99999,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        overflow: "hidden",
        opacity: fading ? 0 : 1,
        transition: "opacity 0.4s ease-out",
        pointerEvents: fading ? "none" : "auto",
      }}
    >
      <canvas
        ref={canvasRef}
        style={{
          position: "absolute",
          inset: 0,
          opacity: 0.35,
          pointerEvents: "none",
        }}
      />

      <div style={{ position: "relative", zIndex: 10, textAlign: "center", display: "flex", flexDirection: "column", alignItems: "center" }}>

        <div style={{ position: "relative", width: 240, height: 240, display: "flex", alignItems: "center", justifyContent: "center", marginBottom: 24 }}>

          <div
            style={{
              position: "absolute",
              width: 190,
              height: 190,
              borderRadius: "50%",
              background: "radial-gradient(circle, rgba(0, 230, 255, 0.4) 0%, rgba(0, 255, 136, 0.2) 50%, transparent 75%)",
              filter: "blur(25px)",
            }}
          />

          <svg viewBox="0 0 260 260" style={{ position: "absolute", inset: 0, width: "100%", height: "100%", overflow: "visible" }}>
            <defs>
              <linearGradient id="scifiCyanGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#00E6FF" stopOpacity="1" />
                <stop offset="100%" stopColor="#00FF88" stopOpacity="0.2" />
              </linearGradient>
              <linearGradient id="scifiGreenGrad" x1="0%" y1="100%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#00FF88" stopOpacity="0.9" />
                <stop offset="100%" stopColor="#00E6FF" stopOpacity="0.1" />
              </linearGradient>
              <filter id="scifiGlow" x="-20%" y="-20%" width="140%" height="140%">
                <feGaussianBlur stdDeviation="3.5" result="blur" />
                <feComposite in="SourceGraphic" in2="blur" operator="over" />
              </filter>
            </defs>

            <circle cx="130" cy="130" r="118" fill="none" stroke="rgba(0, 230, 255, 0.15)" strokeWidth="1" />

            <g style={{ transformOrigin: "center", animation: "spin 12s linear infinite" }}>
              <circle cx="130" cy="130" r="118" fill="none" stroke="rgba(0, 230, 255, 0.6)" strokeWidth="2.5" strokeDasharray="4 20" />
              <circle cx="130" cy="12" r="3" fill="#00E6FF" filter="url(#scifiGlow)" />
              <circle cx="130" cy="248" r="3" fill="#00FF88" filter="url(#scifiGlow)" />
            </g>

            <g style={{ transformOrigin: "center", animation: "spin 3.5s linear infinite" }} filter="url(#scifiGlow)">
              <circle cx="130" cy="130" r="102" fill="none" stroke="url(#scifiCyanGrad)" strokeWidth="3.5" strokeDasharray="210 430" strokeLinecap="round" />
              <circle cx="130" cy="130" r="102" fill="none" stroke="#00FF88" strokeWidth="3" strokeDasharray="40 590" strokeDashoffset="-260" strokeLinecap="round" />
              <circle cx="232" cy="130" r="4.5" fill="#ffffff" />
            </g>

            <g style={{ transformOrigin: "center", animation: "spinReverse 7s linear infinite" }}>
              <circle cx="130" cy="130" r="86" fill="none" stroke="url(#scifiGreenGrad)" strokeWidth="2.5" strokeDasharray="3 14" strokeLinecap="round" />
              <circle cx="130" cy="44" r="2.5" fill="#00E6FF" />
              <circle cx="44" cy="130" r="2.5" fill="#00FF88" />
            </g>

            <circle cx="130" cy="130" r="70" fill="none" stroke="rgba(0, 230, 255, 0.2)" strokeWidth="1" strokeDasharray="10 30" />
          </svg>

          <img
            src="/logo.png"
            alt="SWE Logo"
            style={{
              position: "absolute",
              width: 96,
              height: 96,
              objectFit: "contain",
              zIndex: 10,
              filter: "drop-shadow(0 0 16px rgba(0, 230, 255, 0.8)) drop-shadow(0 0 28px rgba(0, 255, 136, 0.5))",
            }}
          />
        </div>

        <h1 style={{ fontSize: 24, fontWeight: 800, letterSpacing: "1.5px", color: "#ffffff", marginBottom: 12, textShadow: "0 0 16px rgba(0, 230, 255, 0.6)" }}>
          SWE <span style={{ background: "linear-gradient(135deg, #00E6FF 0%, #00FF88 100%)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Attendance System</span>
        </h1>

        <div
          style={{
            display: "inline-flex",
            alignItems: "center",
            gap: 8,
            fontFamily: "monospace",
            fontSize: 12,
            color: "#94a3b8",
            background: "rgba(13, 21, 32, 0.85)",
            padding: "8px 18px",
            borderRadius: 20,
            border: "1px solid #213042",
            boxShadow: "0 0 16px rgba(0, 230, 255, 0.15)",
          }}
        >
          <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#00FF88", boxShadow: "0 0 8px #00FF88" }} />
          <span style={{ color: "#00E6FF", letterSpacing: "0.5px" }}>{statusText}</span>
          <span style={{ display: "inline-block", width: 16, textAlign: "left" }}>{dots}</span>
        </div>
      </div>

      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        @keyframes spinReverse {
          from { transform: rotate(360deg); }
          to { transform: rotate(0deg); }
        }
      `}</style>
    </div>
  );
}

