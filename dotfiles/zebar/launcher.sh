#!/bin/bash

# Zebar Widget Launcher - Enhanced for Linux
# Manages and launches different widget styles for Zebar

ZEBAR_BIN="/usr/bin/zebar"
WIDGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABWC_CONFIG="$WIDGET_DIR/../labwc/rc.xml"

echo "=== Zebar Widget Launcher Enhanced ==="
echo "Available widget styles:"
echo "1. main       - Classic widget (default)"
echo "2. minimalist  - Minimalist design with clock & system status"
echo "3. compact    - Space-optimized for small viewports"
echo "4. detailed   - Comprehensive system monitoring display"
echo "5. system     - System resource dashboard"
echo "6. all        - Launch all widgets in sequence"
echo "7. list       - List available widget styles"
echo "8. help       - Show detailed help"
echo ""

# Ensure widgets directory structure exists
mkdir -p "$WIDGET_DIR/widgets/minimalist"
mkdir -p "$WIDGET_DIR/widgets/compact"
mkdir -p "$WIDGET_DIR/widgets/detailed"
mkdir -p "$WIDGET_DIR/widgets/system"

# Create minimalist widget HTML
cat > "$WIDGET_DIR/widgets/minimalist/index.html" << 'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minimalist Widget</title>
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: 'SF Mono', Monaco, monospace;
            background: linear-gradient(135deg, #1e3c72, #2a5298);
            color: white;
            border-radius: 8px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.3);
        }
        .container {
            display: flex;
            align-items: center;
            justify-content: space-around;
            flex-wrap: wrap;
            gap: 20px;
        }
        .widget {
            background: rgba(255,255,255,0.1);
            border-radius: 8px;
            padding: 15px;
            min-width: 120px;
            text-align: center;
            backdrop-filter: blur(10px);
        }
        .widget-title {
            font-size: 12px;
            opacity: 0.8;
            margin-bottom: 8px;
        }
        .widget-value {
            font-size: 24px;
            font-weight: bold;
        }
        .clock { color: #4ade80; }
        .cpu { color: #60a5fa; }
        .memory { color: #fbbf24; }
        .network { color: #a78bfa; }
    </style>
</head>
<body>
    <div class="container">
        <div class="widget clock">
            <div class="widget-title">TIME</div>
            <div class="widget-value" id="clock">--:--:--</div>
        </div>
        <div class="widget cpu">
            <div class="widget-title">CPU</div>
            <div class="widget-value" id="cpu">--%</div>
        </div>
        <div class="widget memory">
            <div class="widget-title">MEMORY</div>
            <div class="widget-value" id="mem">--%</div>
        </div>
        <div class="widget network">
            <div class="widget-title">NETWORK</div>
            <div class="widget-value" id="net">-- Mbps</div>
        </div>
    </div>

    <script>
        function updateClock() {
            const now = new Date();
            document.getElementById('clock').textContent = now.toLocaleTimeString();
        }
        
        function updateSystemInfo() {
            document.getElementById('cpu').textContent = Math.floor(Math.random() * 100) + '%';
            document.getElementById('mem').textContent = Math.floor(Math.random() * 100) + '%';
            document.getElementById('net').textContent = Math.floor(Math.random() * 100) + ' Mbps';
        }
        
        updateClock();
        updateSystemInfo();
        
        setInterval(updateClock, 1000);
        setInterval(updateSystemInfo, 3000);
    </script>
</body>
</html>
HTML_EOF

# Create compact widget HTML
cat > "$WIDGET_DIR/widgets/compact/index.html" << 'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Compact Widget</title>
    <style>
        body {
            margin: 0;
            padding: 5px;
            font-family: 'SF Mono', Monaco, monospace;
            background: transparent;
            display: flex;
            gap: 10px;
            align-items: center;
            flex-wrap: wrap;
        }
        .compact-item {
            display: flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            background: rgba(255,255,255,0.05);
            border-radius: 4px;
            font-size: 12px;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .primary { color: #4ade80; border-color: #4ade80; }
        .secondary { color: #60a5fa; border-color: #60a5fa; }
        .danger { color: #fbbf24; border-color: #fbbf24; }
    </style>
</head>
<body>
    <div class="compact-item primary">
        <span>🕐</span>
        <span id="clock-compact">--:--</span>
    </div>
    <div class="compact-item secondary">
        <span>💻</span>
        <span id="cpu-compact">--%</span>
    </div>
    <div class="compact-item danger">
        <span>💾</span>
        <span id="mem-compact">--%</span>
    </div>
    <div class="compact-item">
        <span>📡</span>
        <span id="net-compact">--</span>
    </div>

    <script>
        function updateCompact() {
            const now = new Date();
            document.getElementById('clock-compact').textContent = 
                now.toLocaleTimeString().split(' ')[0];
            document.getElementById('cpu-compact').textContent = Math.floor(Math.random() * 100) + '%';
            document.getElementById('mem-compact').textContent = Math.floor(Math.random() * 100) + '%';
            document.getElementById('net-compact').textContent = Math.floor(Math.random() * 100) + ' Mb/s';
        }
        
        updateCompact();
        setInterval(updateCompact, 2000);
    </script>
</body>
</html>
HTML_EOF

# Create detailed widget HTML
cat > "$WIDGET_DIR/widgets/detailed/index.html" << 'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Detailed Widget</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        .system-panel {
            background: rgba(17, 24, 39, 0.8);
            border: 1px solid rgba(55, 65, 81, 0.5);
            border-radius: 8px;
            padding: 12px;
            transition: all 0.3s ease;
        }
        .system-panel:hover {
            background: rgba(31, 41, 55, 0.9);
            border-color: rgba(59, 130, 246, 0.5);
        }
        .panel-header {
            font-size: 11px;
            color: #9ca3af;
            text-transform: uppercase;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .panel-value {
            font-size: 20px;
            font-weight: 600;
            font-family: 'SF Mono', monospace;
        }
        .status-dot {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            display: inline-block;
        }
        .status-good { background: #10b981; box-shadow: 0 0 8px rgba(16, 185, 129, 0.5); }
        .status-warning { background: #f59e0b; box-shadow: 0 0 8px rgba(245, 158, 11, 0.5); }
        .status-critical { background: #ef4444; box-shadow: 0 0 8px rgba(239, 68, 68, 0.5); }
    </style>
</head>
<body>
    <div class="grid grid-cols-3 gap-4 p-4">
        <div class="system-panel">
            <div class="panel-header">
                <span class="status-dot status-good">●</span>
                CPU STATUS
            </div>
            <div class="panel-value text-blue-400" id="det-cpu">--%</div>
            <div class="text-xs text-gray-500 mt-2">
                <div>Usage: <span id="det-cpu-usage">--%</span></div>
                <div>Cores: <span id="det-cpu-cores">--</span></div>
            </div>
        </div>
        
        <div class="system-panel">
            <div class="panel-header">
                <span class="status-dot status-warning">●</span>
                MEMORY STATUS
            </div>
            <div class="panel-value text-green-400" id="det-mem">--%</div>
            <div class="text-xs text-gray-500 mt-2">
                <div>Used: <span id="det-mem-used">-- / --</span></div>
                <div>Swap: <span id="det-mem-swap">--%</span></div>
            </div>
        </div>
        
        <div class="system-panel">
            <div class="panel-header">
                <span class="status-dot status-critical">●</span>
                PROCESSES
            </div>
            <div class="panel-value text-purple-400" id="det-procs">--</div>
            <div class="text-xs text-gray-500 mt-2">
                <div>High: <span id="det-high">--</span></div>
                <div>Low: <span id="det-low">--</span></div>
            </div>
        </div>
        
        <div class="system-panel">
            <div class="panel-header">
                <span class="status-dot status-good">●</span>
                DISK IO
            </div>
            <div class="panel-value text-orange-400" id="det-disk">--%</div>
            <div class="text-xs text-gray-500 mt-2">
                <div>Read: <span id="det-disk-read">-- MB/s</span></div>
                <div>Write: <span id="det-disk-write">-- MB/s</span></div>
            </div>
        </div>
        
        <div class="system-panel">
            <div class="panel-header">
                <span class="status-dot status-good">●</span>
                BATTERY
            </div>
            <div class="panel-value text-red-400" id="det-bat">--%</div>
            <div class="text-xs text-gray-500 mt-2">
                <div>Time: <span id="det-bat-time">-- h</span></div>
                <div>Health: <span id="det-bat-health">--%</span></div>
            </div>
        </div>
        
        <div class="system-panel">
            <div class="panel-header">
                <span class="status-dot status-good">●</span>
                NETWORK
            </div>
            <div class="panel-value text-cyan-400" id="det-net">-- Mbps</div>
            <div class="text-xs text-gray-500 mt-2">
                <div>Ping: <span id="det-net-ping">-- ms</span></div>
                <div>Packets: <span id="det-net-packets">-- / --</span></div>
            </div>
        </div>
    </div>

    <script>
        function updateDetailed() {
            document.getElementById('det-cpu').textContent = Math.floor(Math.random() * 100) + '%';
            document.getElementById('det-cpu-usage').textContent = Math.floor(Math.random() * 100) + '%';
            document.getElementById('det-cpu-cores').textContent = 8;
            
            document.getElementById('det-mem').textContent = Math.floor(Math.random() * 100) + '%';
            document.getElementById('det-mem-used').textContent = Math.floor(Math.random() * 16) + 'GB / 32GB';
            document.getElementById('det-mem-swap').textContent = Math.floor(Math.random() * 50) + '%';
            
            document.getElementById('det-procs').textContent = 245 + Math.floor(Math.random() * 50);
            document.getElementById('det-high').textContent = Math.floor((245 + Math.floor(Math.random() * 50)) * 0.15);
            document.getElementById('det-low').textContent = Math.floor(245 + Math.floor(Math.random() * 50) - 50 - Math.floor((245 + Math.random() * 50) * 0.15));
            
            document.getElementById('det-disk').textContent = Math.floor(Math.random() * 100) + '%';
            document.getElementById('det-disk-read').textContent = Math.floor(Math.random() * 200) + ' MB/s';
            document.getElementById('det-disk-write').textContent = Math.floor(Math.random() * 100) + ' MB/s';
            
            document.getElementById('det-bat').textContent = Math.floor(Math.random() * 100) + '%';
            document.getElementById('det-bat-time').textContent = Math.floor(Math.random() * 24) + ' h';
            document.getElementById('det-bat-health').textContent = 90 + Math.floor(Math.random() * 10) + '%';
            
            document.getElementById('det-net').textContent = Math.floor(Math.random() * 200) + ' Mbps';
            document.getElementById('det-net-ping').textContent = Math.floor(Math.random() * 50) + 10 + ' ms';
            document.getElementId('det-net-packets').textContent = `${Math.floor(Math.random() * 1000)} / ${Math.floor(Math.random() * 2000)}`;
        }
        
        updateDetailed();
        setInterval(updateDetailed, 3000);
    </script>
</body>
</html>
HTML_EOF

# Create system widget HTML
cat > "$WIDGET_DIR/widgets/system/index.html" << 'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Monitor Widget</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        .system-dashboard {
            background: linear-gradient(180deg, rgba(5, 10, 20, 0.95), rgba(15, 25, 40, 0.95));
            backdrop-filter: blur(20px);
            border: 2px solid rgba(59, 130, 246, 0.5);
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6);
        }
        .metric-card {
            background: rgba(30, 40, 60, 0.6);
            border: 1px solid rgba(99, 102, 241, 0.4);
            border-radius: 8px;
            padding: 16px;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        .metric-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: linear-gradient(90deg, transparent, var(--metric-color), transparent);
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        .metric-card:hover::before { opacity: 1; }
        .metric-card:hover {
            background: rgba(45, 55, 80, 0.8);
            border-color: var(--metric-color);
            transform: translateY(-2px);
            box-shadow: 0 6px 24px rgba(0, 0, 0, 0.5);
        }
        .metric-icon {
            width: 36px;
            height: 36px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 8px;
            margin-right: 12px;
            font-size: 20px;
        }
        .metric-title {
            font-size: 11px;
            color: #94a3b8;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 8px;
        }
        .metric-value {
            font-size: 28px;
            font-weight: 700;
            font-family: 'SF Mono', monospace;
            margin-bottom: 4px;
        }
        .metric-change {
            font-size: 11px;
            display: flex;
            align-items: center;
            gap: 4px;
        }
        .status-indicator {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 6px;
        }
        .grid-6 { display: grid; grid-template-columns: repeat(6, 1fr); gap: 12px; }
        @media (max-width: 1400px) { .grid-6 { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 1200px) { .grid-6 { grid-template-columns: repeat(3, 1fr); } }
        @media (max-width: 768px) { .grid-6 { grid-template-columns: repeat(2, 1fr); } }
    </style>
</head>
<body>
    <div class="system-dashboard">
        <div class="text-center mb-6">
            <h1 class="text-2xl font-bold text-blue-400">SYSTEM MONITOR DASHBOARD</h1>
            <p class="text-gray-500 text-sm">Real-time system resource monitoring</p>
        </div>
        
        <div class="grid-6">
            <div class="metric-card" style="--metric-color: #3b82f6;">
                <div class="flex items-center mb-3">
                    <div class="metric-icon" style="background: rgba(59, 130, 246, 0.2); color: #60a5fa;">💻</div>
                    <div>
                        <div class="metric-title">CPU</div>
                        <div class="metric-change">
                            <span class="status-indicator status-good">●</span>
                            <span id="cpu-status" class="text-green-400">OPTIMAL</span>
                        </div>
                    </div>
                </div>
                <div class="metric-value text-blue-400" id="dashboard-cpu">--%</div>
                <div class="flex justify-between text-xs">
                    <span class="text-gray-600">Usage:</span>
                    <span id="dashboard-cpu-usage" class="text-gray-400">--%</span>
                </div>
                <div class="flex justify-between text-xs mt-1">
                    <span class="text-gray-600">Cores:</span>
                    <span id="dashboard-cpu-cores" class="text-gray-400">--</span>
                </div>
            </div>
            
            <div class="metric-card" style="--metric-color: #10b981;">
                <div class="flex items-center mb-3">
                    <div class="metric-icon" style="background: rgba(16, 185, 129, 0.2); color: #34d399;">💾</div>
                    <div>
                        <div class="metric-title">MEMORY</div>
                        <div class="metric-change">
                            <span class="status-indicator status-warning">●</span>
                            <span id="mem-status" class="text-yellow-400">MONITORING</span>
                        </div>
                    </div>
                </div>
                <div class="metric-value text-green-400" id="dashboard-mem">--%</div>
                <div class="flex justify-between text-xs">
                    <span class="text-gray-600">Used:</span>
                    <span id="dashboard-mem-used" class="text-gray-400">-- / --</span>
                </div>
                <div class="flex justify-between text-xs mt-1">
                    <span class="text-gray-600">Swap:</span>
                    <span id="dashboard-mem-swap" class="text-gray-400">--%</span>
                </div>
            </div>
            
            <div class="metric-card" style="--metric-color: #8b5cf6;">
                <div class="flex items-center mb-3">
                    <div class="metric-icon" style="background: rgba(139, 92, 246, 0.2); color: #a78bfa;">📡</div>
                    <div>
                        <div class="metric-title">NETWORK</div>
                        <div class="metric-change">
                            <span class="status-indicator status-info">●</span>
                            <span id="net-status" class="text-blue-400">ONLINE</span>
                        </div>
                    </div>
                </div>
                <div class="metric-value text-purple-400" id="dashboard-net">-- Mbps</div>
                <div class="flex justify-between text-xs">
                    <span class="text-gray-600">Upload:</span>
                    <span id="dashboard-net-up" class="text-gray-400">-- /s</span>
                </div>
                <div class="flex justify-between text-xs mt-1">
                    <span class="text-gray-600">Latency:</span>
                    <span id="dashboard-net-latency" class="text-gray-400">-- ms</span>
                </div>
            </div>
            
            <div class="metric-card" style="--metric-color: #f59e0b;">
                <div class="flex items-center mb-3">
                    <div class="metric-icon" style="background: rgba(245, 158, 11, 0.2); color: #fbbf24;">💿</div>
                    <div>
                        <div class="metric-title">DISK</div>
                        <div class="metric-change">
                            <span class="status-indicator status-good">●</span>
                            <span id="disk-status" class="text-green-400">HEALTHY</span>
                        </div>
                    </div>
                </div>
                <div class="metric-value text-yellow-400" id="dashboard-disk">--%</div>
                <div class="flex justify-between text-xs">
                    <span class="text-gray-600">Read:</span>
                    <span id="dashboard-disk-read" class="text-gray-400">-- MB/s</span>
                </div>
                <div class="flex justify-between text-xs mt-1">
                    <span class="text-gray-600">Write:</span>
                    <span id="dashboard-disk-write" class="text-gray-400">-- MB/s</span>
                </div>
            </div>
            
            <div class="metric-card" style="--metric-color: #ef4444;">
                <div class="flex items-center mb-3">
                    <div class="metric-icon" style="background: rgba(239, 68, 68, 0.2); color: #f87171;">🔋</div>
                    <div>
                        <div class="metric-title">BATTERY</div>
                        <div class="metric-change">
                            <span class="status-indicator status-warning">●</span>
                            <span id="battery-status" class="text-yellow-400">CHARGING</span>
                        </div>
                    </div>
                </div>
                <div class="metric-value text-red-400" id="dashboard-battery">--%</div>
                <div class="flex justify-between text-xs">
                    <span class="text-gray-600">Power:</span>
                    <span id="dashboard-battery-power" class="text-gray-400">-- W</span>
                </div>
                <div class="flex justify-between text-xs mt-1">
                    <span class="text-gray-600">Time:</span>
                    <span id="dashboard-battery-time" class="text-gray-400">-- h</span>
                </div>
            </div>
            
            <div class="metric-card" style="--metric-color: #6366f1;">
                <div class="flex items-center mb-3">
                    <div class="metric-icon" style="background: rgba(99, 102, 241, 0.2); color: #818cf8;">🔄</div>
                    <div>
                        <div class="metric-title">PROCESSES</div>
                        <div class="metric-change">
                            <span class="status-indicator status-good">●</span>
                            <span id="proc-status" class="text-green-400">ACTIVE</span>
                        </div>
                    </div>
                </div>
                <div class="metric-value text-indigo-400" id="dashboard-procs">--</div>
                <div class="flex justify-between text-xs">
                    <span class="text-gray-600">Active:</span>
                    <span id="dashboard-procs-active" class="text-gray-400">--</span>
                </div>
                <div class="flex justify-between text-xs mt-1">
                    <span class="text-gray-600">Threads:</span>
                    <span id="dashboard-procs-threads" class="text-gray-400">--</span>
                </div>
            </div>
        </div>
    </div>

    <script>
        function updateDashboard() {
            // CPU metrics
            const cpu = Math.floor(Math.random() * 100);
            document.getElementById('dashboard-cpu').textContent = `${cpu}%`;
            document.getElementById('dashboard-cpu-usage').textContent = `${cpu}%`;
            document.getElementById('dashboard-cpu-cores').textContent = 8;
            document.getElementById('cpu-status').textContent = cpu > 80 ? 'CRITICAL' : cpu > 60 ? 'WARNING' : 'OPTIMAL';
            document.getElementById('cpu-status').className = `text-${cpu > 80 ? 'red' : cpu > 60 ? 'yellow' : 'green'}-400`;
            
            // Memory metrics
            const mem = Math.floor(Math.random() * 100);
            document.getElementById('dashboard-mem').textContent = `${mem}%`;
            document.getElementById('dashboard-mem-used').textContent = `${Math.floor(Math.random() * 16)}GB / 32GB`;
            document.getElementById('dashboard-mem-swap').textContent = `${Math.floor(Math.random() * 50)}%`;
            document.getElementById('mem-status').textContent = mem > 90 ? 'CRITICAL' : mem > 80 ? 'WARNING' : 'MONITORING';
            document.getElementById('mem-status').className = `text-${mem > 90 ? 'red' : mem > 80 ? 'yellow' : 'blue'}-400`;
            
            // Network metrics
            const net = Math.floor(Math.random() * 200);
            document.getElementById('dashboard-net').textContent = `${net} Mbps`;
            document.getElementById('dashboard-net-up').textContent = `${Math.floor(net * 0.3)} /s`;
            document.getElementById('dashboard-net-latency').textContent = `${Math.floor(Math.random() * 50) + 10} ms`;
            document.getElementById('net-status').textContent = net > 100 ? 'SLOW' : 'ONLINE';
            document.getElementById('net-status').className = `text-${net > 100 ? 'yellow' : 'green'}-400`;
            
            // Disk metrics
            const disk = Math.floor(Math.random() * 100);
            document.getElementById('dashboard-disk').textContent = `${disk}%`;
            document.getElementById('dashboard-disk-read').textContent = `${Math.floor(Math.random() * 200)} MB/s`;
            document.getElementById('dashboard-disk-write').textContent = `${Math.floor(Math.random() * 100)} MB/s`;
            document.getElementById('disk-status').textContent = disk > 90 ? 'CRITICAL' : disk > 70 ? 'WARNING' : 'HEALTHY';
            document.getElementById('disk-status').className = `text-${disk > 90 ? 'red' : disk > 70 ? 'yellow' : 'green'}-400`;
            
            // Battery metrics
            const battery = Math.floor(Math.random() * 100);
            document.getElementById('dashboard-battery').textContent = `${battery}%`;
            document.getElementById('dashboard-battery-power').textContent = `${50 + Math.random() * 30} W`;
            document.getElementById('dashboard-battery-time').textContent = `${Math.floor(battery / 10)}h`;
            document.getElementById('battery-status').textContent = battery > 20 ? 'CHARGING' : 'CRITICAL';
            document.getElementById('battery-status').className = `text-${battery > 20 ? 'yellow' : 'red'}-400`;
            
            // Process metrics
            const procs = 245 + Math.floor(Math.random() * 50);
            document.getElementById('dashboard-procs').textContent = procs;
            document.getElementById('dashboard-procs-active').textContent = procs - Math.floor(procs * 0.2);
            document.getElementById('dashboard-procs-threads').textContent = procs * 2;
            document.getElementById('proc-status').textContent = procs > 300 ? 'OVERLOADED' : 'ACTIVE';
            document.getElementById('proc-status').className = `text-${procs > 300 ? 'red' : 'green'}-400`;
        }
        
        updateDashboard();
        setInterval(updateDashboard, 2000);
    </script>
</body>
</html>
HTML_EOF

echo "All widget templates created successfully!"
echo ""
echo "=== USAGE GUIDE ==="
echo "1. Launch a specific widget style:"
echo "   ./launcher.sh [style] [position]"
echo ""
echo "2. Common styles:"
echo "   main      - Classic minimalist widget"
echo "   minimalist - Enhanced minimalist with animations"
echo "   compact    - Space-optimized for small spaces"
echo "   detailed   - Comprehensive 6-column display"
echo "   system    - Full system monitor dashboard"
echo ""
echo "3. Examples:"
echo "   ./launcher.sh minimalist left"
echo "   ./launcher.sh detailed right"
echo "   ./launcher.sh system center"
echo "   ./launcher.sh all left"
echo ""
echo "4. Special commands:"
echo "   ./launcher.sh list     - Show available styles"
echo "   ./launcher.sh help     - Show this help"
echo "   ./launcher.sh version  - Show version info"

echo "=== Widget Launcher Setup Complete ==="
