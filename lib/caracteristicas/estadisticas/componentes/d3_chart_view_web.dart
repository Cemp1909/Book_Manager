import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'package:book_manager/caracteristicas/estadisticas/componentes/d3_chart_data.dart';

class D3ChartView extends StatefulWidget {
  final String title;
  final String? subtitle;
  final D3ChartKind kind;
  final List<D3ChartDatum> data;
  final double height;

  const D3ChartView({
    super.key,
    required this.title,
    this.subtitle,
    required this.kind,
    required this.data,
    this.height = 320,
  });

  @override
  State<D3ChartView> createState() => _D3ChartViewState();
}

class _D3ChartViewState extends State<D3ChartView> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'd3-chart-${DateTime.now().microsecondsSinceEpoch}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      return web.HTMLIFrameElement()
        ..srcdoc = _buildHtml().toJS
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: widget.height,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }

  String _buildHtml() {
    final payload = jsonEncode({
      'title': widget.title,
      'subtitle': widget.subtitle ?? '',
      'kind': widget.kind.name,
      'data': widget.data.map((datum) => datum.toJson()).toList(),
    });

    return '''
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script src="https://cdn.jsdelivr.net/npm/d3@7/dist/d3.min.js"></script>
  <style>
    * { box-sizing: border-box; }
    html, body, #chart {
      width: 100%;
      height: 100%;
      margin: 0;
      font-family: Roboto, Arial, sans-serif;
      background: #FFFFFF;
      color: #17212B;
    }
    #chart {
      height: 100%;
      display: flex;
      flex-direction: column;
      padding: 16px;
      border-left: 4px solid #008F83;
    }
    .head {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 12px;
      margin-bottom: 10px;
    }
    .title {
      margin: 0;
      font-size: 17px;
      line-height: 1.15;
      font-weight: 900;
      letter-spacing: .02em;
      text-transform: uppercase;
    }
    .subtitle {
      margin: 4px 0 0;
      color: #64748B;
      font-size: 12px;
      font-weight: 700;
    }
    .badge {
      padding: 6px 8px;
      border-radius: 8px;
      background: #F3F6F4;
      color: #075E59;
      font-size: 11px;
      font-weight: 900;
      white-space: nowrap;
    }
    .plot {
      position: relative;
      flex: 1;
      min-height: 180px;
    }
    .empty {
      height: 100%;
      display: grid;
      place-items: center;
      color: #64748B;
      font-weight: 800;
      text-align: center;
    }
    .label {
      fill: #17212B;
      font-size: 12px;
      font-weight: 900;
    }
    .muted {
      fill: #64748B;
      color: #64748B;
      font-size: 11px;
      font-weight: 700;
    }
    .axis path, .axis line { stroke: #DDE6DD; }
    .grid line { stroke: #E8EFE8; stroke-dasharray: 4 4; }
    .legend {
      display: flex;
      flex-wrap: wrap;
      gap: 8px 12px;
      margin-top: 10px;
    }
    .legend-item {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      color: #64748B;
      font-size: 12px;
      font-weight: 800;
    }
    .dot {
      width: 10px;
      height: 10px;
      border-radius: 999px;
      display: inline-block;
    }
    .analysis {
      margin-top: 12px;
      padding: 10px 12px;
      border-radius: 8px;
      background: #F7FAF8;
      border: 1px solid #DDE6DD;
      color: #17212B;
      font-size: 12px;
      line-height: 1.35;
      font-weight: 700;
    }
    .analysis strong { color: #075E59; }
    .tooltip {
      position: absolute;
      pointer-events: none;
      opacity: 0;
      transform: translate(-50%, -112%);
      min-width: 150px;
      padding: 9px 10px;
      border-radius: 8px;
      background: rgba(23, 33, 43, .94);
      color: white;
      box-shadow: 0 16px 32px rgba(23, 33, 43, .2);
      font-size: 12px;
      line-height: 1.35;
      z-index: 4;
    }
    .tooltip b { display: block; margin-bottom: 2px; }
    .selected {
      filter: drop-shadow(0 8px 12px rgba(23, 33, 43, .18));
      stroke: #17212B !important;
      stroke-width: 2.5px !important;
    }
    svg { overflow: visible; }
  </style>
</head>
<body>
  <div id="chart">
    <div class="head">
      <div>
        <h2 class="title"></h2>
        <p class="subtitle"></p>
      </div>
      <div class="badge">D3.js interactivo</div>
    </div>
    <div class="plot"></div>
    <div class="analysis"></div>
  </div>
  <script>
    const payload = $payload;
    const root = d3.select("#chart");
    const plot = root.select(".plot");
    const analysis = root.select(".analysis");
    const tooltip = plot.append("div").attr("class", "tooltip");
    root.select(".title").text(payload.title);
    root.select(".subtitle").text(payload.subtitle || "Clic en un elemento para ver el analisis.");

    const rawData = payload.data || [];
    const data = rawData.filter((item) => Number(item.value) > 0 || Number(item.secondaryValue) > 0);
    const total = d3.sum(data, (d) => Number(d.value) || 0);

    if (!data.length) {
      plot.append("div").attr("class", "empty").text("Sin datos para graficar");
      analysis.html("<strong>Analisis:</strong> No hay datos suficientes para calcular una lectura.");
    } else {
      setAnalysis(data[0]);
      if (payload.kind === "donut") drawDonut(data);
      else if (payload.kind === "bubble") drawBubble(data);
      else drawBars(data);
    }

    function chartSize(minHeight = 190) {
      const bounds = plot.node().getBoundingClientRect();
      return {
        width: Math.max(300, bounds.width),
        height: Math.max(minHeight, bounds.height)
      };
    }

    function formatValue(value) {
      const n = Number(value) || 0;
      return n >= 1000000 ? (n / 1000000).toFixed(1) + "M"
        : n >= 1000 ? (n / 1000).toFixed(0) + "K"
        : d3.format(",")(n);
    }

    function share(value) {
      if (!total) return "0%";
      return d3.format(".1%")((Number(value) || 0) / total);
    }

    function setAnalysis(d) {
      const value = Number(d.value) || 0;
      const pct = share(value);
      const detail = d.detail || `Representa \${pct} del total visible en esta grafica.`;
      analysis.html(`<strong>\${d.label}:</strong> \${formatValue(value)} · \${pct}. \${detail}`);
    }

    function showTip(event, d) {
      tooltip
        .style("opacity", 1)
        .style("left", event.offsetX + "px")
        .style("top", event.offsetY + "px")
        .html(`<b>\${d.label}</b>Valor: \${formatValue(d.value)}<br>Participacion: \${share(d.value)}`);
    }

    function hideTip() {
      tooltip.style("opacity", 0);
    }

    function selectMark(selection, d) {
      d3.selectAll(".mark").classed("selected", false).style("opacity", .72);
      selection.classed("selected", true).style("opacity", 1);
      setAnalysis(d);
    }

    function drawDonut(data) {
      const size = chartSize(190);
      const radius = Math.min(size.width, size.height) / 2;
      const svg = plot.append("svg")
        .attr("width", size.width)
        .attr("height", size.height)
        .attr("viewBox", [0, 0, size.width, size.height]);
      const defs = svg.append("defs");
      data.forEach((d, i) => {
        const grad = defs.append("linearGradient")
          .attr("id", `grad-\${i}`)
          .attr("x1", "0%").attr("x2", "100%");
        grad.append("stop").attr("offset", "0%").attr("stop-color", d.color).attr("stop-opacity", .72);
        grad.append("stop").attr("offset", "100%").attr("stop-color", d.color);
      });

      const group = svg.append("g")
        .attr("transform", `translate(\${size.width / 2},\${size.height / 2})`);
      const pie = d3.pie().sort(null).padAngle(.025).value((d) => d.value);
      const arc = d3.arc().innerRadius(radius * 0.56).outerRadius(radius * 0.88).cornerRadius(6);
      const labelArc = d3.arc().innerRadius(radius * 0.73).outerRadius(radius * 0.73);

      const paths = group.selectAll("path")
        .data(pie(data))
        .join("path")
        .attr("class", "mark")
        .attr("fill", (d, i) => `url(#grad-\${i})`)
        .attr("stroke", "#FFFFFF")
        .attr("stroke-width", 4)
        .style("cursor", "pointer")
        .on("mousemove", (event, d) => showTip(event, d.data))
        .on("mouseleave", hideTip)
        .on("click", function(event, d) { selectMark(d3.select(this), d.data); })
        .transition()
        .duration(800)
        .attrTween("d", function(d) {
          const interpolate = d3.interpolate({ startAngle: 0, endAngle: 0 }, d);
          return (t) => arc(interpolate(t));
        });

      group.selectAll("text")
        .data(pie(data))
        .join("text")
        .attr("class", "label")
        .attr("text-anchor", "middle")
        .attr("transform", (d) => `translate(\${labelArc.centroid(d)})`)
        .text((d) => formatValue(d.data.value));

      group.append("text")
        .attr("text-anchor", "middle")
        .attr("dy", "-.1em")
        .attr("class", "label")
        .style("font-size", "18px")
        .text(formatValue(total));
      group.append("text")
        .attr("text-anchor", "middle")
        .attr("dy", "1.2em")
        .attr("class", "muted")
        .text("total");

      renderLegend(data);
      setTimeout(() => selectMark(d3.select(group.select(".mark").node()), data[0]), 850);
    }

    function drawBars(data) {
      const size = chartSize(205);
      const margin = { top: 12, right: 16, bottom: 50, left: 48 };
      const width = size.width - margin.left - margin.right;
      const height = size.height - margin.top - margin.bottom;
      const svg = plot.append("svg")
        .attr("width", size.width)
        .attr("height", size.height)
        .attr("viewBox", [0, 0, size.width, size.height]);
      const defs = svg.append("defs");
      const gradient = defs.append("linearGradient").attr("id", "barGradient").attr("x1", "0%").attr("x2", "0%").attr("y1", "0%").attr("y2", "100%");
      gradient.append("stop").attr("offset", "0%").attr("stop-color", "#008F83");
      gradient.append("stop").attr("offset", "100%").attr("stop-color", "#35A6D6");

      const group = svg.append("g").attr("transform", `translate(\${margin.left},\${margin.top})`);
      const x = d3.scaleBand().domain(data.map((d) => d.label)).range([0, width]).padding(0.28);
      const y = d3.scaleLinear().domain([0, d3.max(data, (d) => d.value) || 1]).nice().range([height, 0]);

      group.append("g")
        .attr("class", "grid")
        .call(d3.axisLeft(y).ticks(4).tickSize(-width).tickFormat(""))
        .call((axis) => axis.select(".domain").remove());
      group.append("g")
        .attr("class", "axis")
        .attr("transform", `translate(0,\${height})`)
        .call(d3.axisBottom(x).tickSizeOuter(0))
        .call((axis) => axis.selectAll("text")
          .attr("class", "muted")
          .attr("dy", "1em")
          .attr("transform", "rotate(-15)")
          .style("text-anchor", "end"));
      group.append("g")
        .attr("class", "axis")
        .call(d3.axisLeft(y).ticks(4).tickFormat(formatValue))
        .call((axis) => axis.selectAll("text").attr("class", "muted"))
        .call((axis) => axis.select(".domain").remove());

      const bars = group.selectAll("rect.bar")
        .data(data)
        .join("rect")
        .attr("class", "mark bar")
        .attr("x", (d) => x(d.label))
        .attr("width", x.bandwidth())
        .attr("y", height)
        .attr("height", 0)
        .attr("rx", 8)
        .attr("fill", (d) => d.color || "url(#barGradient)")
        .style("cursor", "pointer")
        .on("mousemove", showTip)
        .on("mouseleave", hideTip)
        .on("click", function(event, d) { selectMark(d3.select(this), d); });

      bars.transition()
        .duration(850)
        .delay((d, i) => i * 60)
        .attr("y", (d) => y(d.value))
        .attr("height", (d) => height - y(d.value));

      group.selectAll(".value")
        .data(data)
        .join("text")
        .attr("class", "label")
        .attr("text-anchor", "middle")
        .attr("x", (d) => (x(d.label) || 0) + x.bandwidth() / 2)
        .attr("y", (d) => y(d.value) - 8)
        .text((d) => formatValue(d.value));

      setTimeout(() => selectMark(d3.select(group.select(".mark").node()), data[0]), 900);
    }

    function drawBubble(data) {
      const size = chartSize(220);
      const margin = { top: 12, right: 16, bottom: 44, left: 52 };
      const width = size.width - margin.left - margin.right;
      const height = size.height - margin.top - margin.bottom;
      const svg = plot.append("svg")
        .attr("width", size.width)
        .attr("height", size.height)
        .attr("viewBox", [0, 0, size.width, size.height]);
      const group = svg.append("g").attr("transform", `translate(\${margin.left},\${margin.top})`);
      const x = d3.scaleLinear().domain([0, d3.max(data, (d) => d.value) || 1]).nice().range([0, width]);
      const y = d3.scaleLinear().domain([0, d3.max(data, (d) => d.secondaryValue || 0) || 1]).nice().range([height, 0]);
      const r = d3.scaleSqrt().domain([0, d3.max(data, (d) => d.size || d.value) || 1]).range([7, 26]);

      group.append("g")
        .attr("class", "grid")
        .call(d3.axisLeft(y).ticks(4).tickSize(-width).tickFormat(""))
        .call((axis) => axis.select(".domain").remove());
      group.append("g").attr("class", "axis").attr("transform", `translate(0,\${height})`)
        .call(d3.axisBottom(x).ticks(4).tickFormat(formatValue))
        .call((axis) => axis.selectAll("text").attr("class", "muted"));
      group.append("g").attr("class", "axis")
        .call(d3.axisLeft(y).ticks(4).tickFormat(formatValue))
        .call((axis) => axis.selectAll("text").attr("class", "muted"))
        .call((axis) => axis.select(".domain").remove());

      group.append("text").attr("class", "muted").attr("x", width).attr("y", height + 36).attr("text-anchor", "end").text("precio");
      group.append("text").attr("class", "muted").attr("x", -38).attr("y", -2).text("stock");

      const bubbles = group.selectAll("circle")
        .data(data)
        .join("circle")
        .attr("class", "mark")
        .attr("cx", (d) => x(d.value))
        .attr("cy", (d) => y(d.secondaryValue || 0))
        .attr("r", 0)
        .attr("fill", (d) => d.color)
        .attr("fill-opacity", .68)
        .attr("stroke", "#FFFFFF")
        .attr("stroke-width", 2)
        .style("cursor", "pointer")
        .on("mousemove", showTip)
        .on("mouseleave", hideTip)
        .on("click", function(event, d) { selectMark(d3.select(this), d); });

      bubbles.transition()
        .duration(850)
        .delay((d, i) => i * 70)
        .attr("r", (d) => r(d.size || d.value));

      setTimeout(() => selectMark(d3.select(group.select(".mark").node()), data[0]), 900);
    }

    function renderLegend(data) {
      const legend = root.insert("div", ".analysis").attr("class", "legend");
      const item = legend.selectAll("div").data(data.slice(0, 6)).join("div").attr("class", "legend-item");
      item.append("span").attr("class", "dot").style("background", (d) => d.color);
      item.append("span").text((d) => `\${d.label}: \${formatValue(d.value)}`);
    }
  </script>
</body>
</html>
''';
  }
}
