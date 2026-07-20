import { useEffect, useId, useRef, useState } from "react";
import { Html5Qrcode } from "html5-qrcode";
import { Camera, Square } from "lucide-react";
import { useToast } from "../lib/ToastContext";

export function ScannerPanel({ onScanned }) {
  const regionId = `scanner-${useId().replace(/[^a-zA-Z0-9]/g, "")}`;
  const scannerRef = useRef(null);
  const [scanning, setScanning] = useState(false);
  const notify = useToast();

  async function stopScanner() {
    const instance = scannerRef.current;
    scannerRef.current = null;
    if (instance) {
      try {
        if (instance.isScanning) await instance.stop();
        instance.clear();
      } catch {
        // scanner already torn down
      }
    }
    setScanning(false);
  }

  useEffect(() => {
    return () => {
      stopScanner();
    };
  }, []);

  async function startScanner() {
    try {
      const instance = new Html5Qrcode(regionId);
      scannerRef.current = instance;
      await instance.start(
        { facingMode: "environment" },
        { fps: 10, qrbox: 240 },
        (decodedText) => {
          onScanned(decodedText);
          stopScanner();
          notify("QR captured.", "success");
        },
        () => {},
      );
      setScanning(true);
    } catch (error) {
      notify(error?.message || "Camera unavailable. Paste the payload instead.", "danger");
      scannerRef.current = null;
    }
  }

  return (
    <div className="scanner-block">
      <div className="toolbar">
        <h3>Scan Attendance</h3>
        <button type="button" className="btn btn-secondary" onClick={scanning ? stopScanner : startScanner}>
          {scanning ? (
            <>
              <Square size={16} /> Stop
            </>
          ) : (
            <>
              <Camera size={16} /> Camera
            </>
          )}
        </button>
      </div>
      <div id={regionId} className={`camera-region${scanning ? "" : " hidden"}`} />
    </div>
  );
}
