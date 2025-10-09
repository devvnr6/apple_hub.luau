(function(){
  'use strict';

  // Year
  const yearEl = document.getElementById('year');
  if (yearEl) yearEl.textContent = String(new Date().getFullYear());

  // HUD Canvas Animation - simple fast-moving lines + pulses
  const canvas = document.getElementById('hud-canvas');
  if (canvas) {
    const ctx = canvas.getContext('2d');
    const DPR = Math.max(1, Math.floor(window.devicePixelRatio || 1));

    function resize(){
      const { width, height } = canvas.getBoundingClientRect();
      canvas.width = Math.floor(width * DPR);
      canvas.height = Math.floor(height * DPR);
      ctx.scale(DPR, DPR);
    }

    const lines = Array.from({ length: 20 }, () => ({
      y: Math.random(),
      speed: 0.4 + Math.random() * 1.2,
      alpha: 0.2 + Math.random() * 0.6
    }));

    const pulses = Array.from({ length: 6 }, () => ({
      x: Math.random(),
      y: Math.random(),
      r: 8 + Math.random() * 24,
      t: Math.random() * Math.PI * 2
    }));

    function draw(){
      const { width, height } = canvas.getBoundingClientRect();
      ctx.clearRect(0,0,width,height);

      // grid
      ctx.strokeStyle = 'rgba(255,255,0,0.05)';
      ctx.lineWidth = 1;
      for (let i = 0; i < width; i += 40) {
        ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, height); ctx.stroke();
      }
      for (let j = 0; j < height; j += 28) {
        ctx.beginPath(); ctx.moveTo(0, j); ctx.lineTo(width, j); ctx.stroke();
      }

      // lines
      ctx.strokeStyle = 'rgba(255,255,0,0.35)';
      ctx.lineWidth = 2;
      lines.forEach(line => {
        line.y += line.speed / 800;
        if (line.y > 1) line.y = 0;
        const y = line.y * height;
        ctx.globalAlpha = line.alpha;
        ctx.beginPath();
        ctx.moveTo(0, y);
        for (let x = 0; x <= width; x += 20) {
          const n = Math.sin((x + performance.now() * 0.7) * 0.01);
          ctx.lineTo(x, y + n * 6);
        }
        ctx.stroke();
      });
      ctx.globalAlpha = 1;

      // pulses
      pulses.forEach(p => {
        p.t += 0.05;
        const px = p.x * width, py = p.y * height;
        const pr = p.r + Math.sin(p.t) * 6;
        ctx.beginPath();
        ctx.arc(px, py, pr, 0, Math.PI * 2);
        ctx.strokeStyle = 'rgba(255,255,0,0.2)';
        ctx.lineWidth = 1.5;
        ctx.stroke();
      });

      requestAnimationFrame(draw);
    }

    resize();
    draw();
    window.addEventListener('resize', resize);
  }

  // System log
  const logEl = document.getElementById('log');
  const start = Date.now();
  const queue = [
    { t: 400,  msg: '<span class="ok">ONLINE</span> :: AUTH RELAY STABLE' },
    { t: 900,  msg: 'Pulling <span class="crit">PLAYER DATA</span> :: DATA STREAM ACTIVE' },
    { t: 1400, msg: 'EGO MATRIX :: <span class="ok">UNLOCKED</span>' },
    { t: 2100, msg: 'INJECTION CHANNEL :: ARMED' },
    { t: 2800, msg: 'ANOMALY WATCH :: 0 CRITICAL | 3 WARN' },
    { t: 3500, msg: 'ALGORITHM BREAKPOINTS :: REGRESSION Δ 0.03' }
  ];
  function stamp(){
    const dt = Date.now() - start;
    const s = (dt / 1000).toFixed(2).padStart(6,'0');
    return `[${s}s]`;
  }
  function append(text){
    if (!logEl) return;
    const div = document.createElement('div');
    div.className = 'log-entry';
    div.innerHTML = `<span class="stamp">${stamp()}</span> ${text}`;
    logEl.appendChild(div);
    logEl.parentElement.scrollTop = logEl.parentElement.scrollHeight;
  }
  if (logEl) {
    queue.forEach(item => setTimeout(() => append(item.msg), item.t));
    setInterval(() => {
      const latency = (20 + Math.random()*30).toFixed(1);
      append(`HEARTBEAT :: LINK ${latency}ms`);
    }, 3000);
  }

  // CTA focus ring sync with mouse for urgency
  const cta = document.querySelector('[data-cta]');
  if (cta) {
    cta.addEventListener('mousemove', (e) => {
      const rect = cta.getBoundingClientRect();
      const x = e.clientX - rect.left; const y = e.clientY - rect.top;
      cta.style.boxShadow = `0 0 0 1px #000, 0 8px 40px rgba(255,255,0,0.4), inset 0 0 0 9999px rgba(255,255,0,0.0)`;
      cta.style.transform = 'translateZ(0)';
    });
  }
})();
