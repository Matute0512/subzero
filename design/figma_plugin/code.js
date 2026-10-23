// SubZero Design Generator - Figma Plugin API
// Generador automatizado de Design Tokens, Componentes y Pantallas para SubZero

(async () => {
  // Cargar fuentes necesarias
  await Promise.all([
    figma.loadFontAsync({ family: "Inter", style: "Regular" }),
    figma.loadFontAsync({ family: "Inter", style: "Medium" }),
    figma.loadFontAsync({ family: "Inter", style: "Semi Bold" }),
    figma.loadFontAsync({ family: "Inter", style: "Bold" })
  ]);

  // Helpers de color
  const hexToRgb = (hex) => {
    const c = hex.replace("#", "");
    return {
      r: parseInt(c.substring(0, 2), 16) / 255,
      g: parseInt(c.substring(2, 4), 16) / 255,
      b: parseInt(c.substring(4, 6), 16) / 255
    };
  };

  const solidPaint = (hex, opacity = 1) => ({
    type: "SOLID",
    color: hexToRgb(hex),
    opacity: opacity
  });

  const gradientPaint = (hexStart, hexEnd) => ({
    type: "GRADIENT_LINEAR",
    gradientTransform: [
      [1, 0, 0],
      [0, 1, 0]
    ],
    gradientStops: [
      { position: 0, color: { ...hexToRgb(hexStart), a: 1 } },
      { position: 1, color: { ...hexToRgb(hexEnd), a: 1 } }
    ]
  });

  // Tokens de color
  const C = {
    bgDark: "#0A192F",
    surface: "#112240",
    surfaceVariant: "#233554",
    primary: "#0077B6",
    secondary: "#48CAE4",
    textPrimary: "#F8F9FA",
    textSecondary: "#8892B0",
    gold: "#FFD166",
    goldBg: "#332A15",
    critBg: "#311013",
    critText: "#FF5252",
    warnBg: "#2E1E0F",
    warnText: "#FFA726",
    safeBg: "#0C2B35",
    safeText: "#00B4D8"
  };

  // Helper para crear texto
  const createText = (characters, size = 14, weight = "Regular", colorHex = C.textPrimary) => {
    const textNode = figma.createText();
    let style = "Regular";
    if (weight === "Medium") style = "Medium";
    if (weight === "SemiBold" || weight === "Semi Bold") style = "Semi Bold";
    if (weight === "Bold") style = "Bold";

    textNode.fontName = { family: "Inter", style };
    textNode.fontSize = size;
    textNode.characters = characters;
    textNode.fills = [solidPaint(colorHex)];
    return textNode;
  };

  // Helper para Badges de urgencia
  const createUrgencyBadge = (text, bgHex, textHex) => {
    const badge = figma.createFrame();
    badge.name = `UrgencyBadge / ${text}`;
    badge.layoutMode = "HORIZONTAL";
    badge.primaryAxisSizingMode = "AUTO";
    badge.counterAxisSizingMode = "AUTO";
    badge.paddingLeft = 8;
    badge.paddingRight = 8;
    badge.paddingTop = 4;
    badge.paddingBottom = 4;
    badge.cornerRadius = 999;
    badge.fills = [solidPaint(bgHex)];

    const label = createText(text, 11, "Medium", textHex);
    badge.appendChild(label);
    return badge;
  };

  // Helper para Botón Primario
  const createPrimaryButton = (label, width = 342) => {
    const btn = figma.createFrame();
    btn.name = "PrimaryButton";
    btn.layoutMode = "HORIZONTAL";
    btn.primaryAxisAlignItems = "CENTER";
    btn.counterAxisAlignItems = "CENTER";
    btn.resize(width, 52);
    btn.cornerRadius = 16;
    btn.fills = [gradientPaint(C.primary, C.secondary)];

    const txt = createText(label, 16, "Bold", "#FFFFFF");
    btn.appendChild(txt);
    return btn;
  };

  // Helper para Tarjeta de Alimento
  const createItemCard = (categoryIcon, name, location, urgencyText, urgBg, urgTxt, hasBell = true) => {
    const card = figma.createFrame();
    card.name = `InventoryItemCard / ${name}`;
    card.layoutMode = "HORIZONTAL";
    card.counterAxisAlignItems = "CENTER";
    card.primaryAxisSizingMode = "FIXED";
    card.counterAxisSizingMode = "AUTO";
    card.resize(342, 76);
    card.paddingLeft = 14;
    card.paddingRight = 14;
    card.paddingTop = 12;
    card.paddingBottom = 12;
    card.itemSpacing = 12;
    card.cornerRadius = 16;
    card.fills = [solidPaint(C.surface)];
    card.strokes = [solidPaint(C.surfaceVariant)];
    card.strokeWeight = 1;

    // Icono categoría
    const iconContainer = figma.createFrame();
    iconContainer.resize(44, 44);
    iconContainer.cornerRadius = 12;
    iconContainer.fills = [solidPaint(C.surfaceVariant)];
    iconContainer.layoutMode = "HORIZONTAL";
    iconContainer.primaryAxisAlignItems = "CENTER";
    iconContainer.counterAxisAlignItems = "CENTER";
    const iconText = createText(categoryIcon, 20, "Regular", C.textPrimary);
    iconContainer.appendChild(iconText);
    card.appendChild(iconContainer);

    // Info Central (Nombre + Ubicación)
    const infoCol = figma.createFrame();
    infoCol.layoutMode = "VERTICAL";
    infoCol.primaryAxisSizingMode = "AUTO";
    infoCol.counterAxisSizingMode = "FIXED";
    infoCol.resize(150, 48);
    infoCol.itemSpacing = 4;
    infoCol.fills = [];

    const title = createText(name, 15, "Semi Bold", C.textPrimary);
    const subtitle = createText(location, 12, "Regular", C.textSecondary);
    infoCol.appendChild(title);
    infoCol.appendChild(subtitle);
    card.appendChild(infoCol);

    // Derecha (Badge + Campana)
    const rightCol = figma.createFrame();
    rightCol.layoutMode = "VERTICAL";
    rightCol.counterAxisAlignItems = "MAX";
    rightCol.primaryAxisSizingMode = "AUTO";
    rightCol.counterAxisSizingMode = "AUTO";
    rightCol.itemSpacing = 6;
    rightCol.fills = [];

    const badge = createUrgencyBadge(urgencyText, urgBg, urgTxt);
    rightCol.appendChild(badge);

    if (hasBell) {
      const bell = createText("🔔", 11, "Regular", C.secondary);
      rightCol.appendChild(bell);
    }
    card.appendChild(rightCol);

    return card;
  };

  // Helper para FilterChip
  const createFilterChip = (label, isActive = false) => {
    const chip = figma.createFrame();
    chip.name = `FilterChip / ${label}`;
    chip.layoutMode = "HORIZONTAL";
    chip.primaryAxisSizingMode = "AUTO";
    chip.counterAxisSizingMode = "AUTO";
    chip.paddingLeft = 14;
    chip.paddingRight = 14;
    chip.paddingTop = 8;
    chip.paddingBottom = 8;
    chip.cornerRadius = 999;
    if (isActive) {
      chip.fills = [solidPaint(C.primary)];
      const txt = createText(label, 13, "Semi Bold", "#FFFFFF");
      chip.appendChild(txt);
    } else {
      chip.fills = [solidPaint(C.surface)];
      chip.strokes = [solidPaint(C.surfaceVariant)];
      chip.strokeWeight = 1;
      const txt = createText(label, 13, "Regular", C.textSecondary);
      chip.appendChild(txt);
    }
    return chip;
  };

  // Helper de Status Bar iOS/Android
  const createStatusBar = () => {
    const bar = figma.createFrame();
    bar.name = "StatusBar";
    bar.resize(390, 44);
    bar.fills = [];
    bar.layoutMode = "HORIZONTAL";
    bar.primaryAxisAlignItems = "SPACE_BETWEEN";
    bar.counterAxisAlignItems = "CENTER";
    bar.paddingLeft = 24;
    bar.paddingRight = 24;

    const time = createText("09:41", 14, "Semi Bold", C.textPrimary);
    const icons = createText("􀋑 􀙇 􀛨", 13, "Regular", C.textPrimary);
    bar.appendChild(time);
    bar.appendChild(icons);
    return bar;
  };

  // =========================================================
  // PANTALLA 1: Home Dashboard (390x844)
  // =========================================================
  const screen1 = figma.createFrame();
  screen1.name = "home_inventory_screen";
  screen1.resize(390, 844);
  screen1.fills = [solidPaint(C.bgDark)];
  screen1.clipsContent = true;

  // Status Bar
  screen1.appendChild(createStatusBar());

  // Header
  const header = figma.createFrame();
  header.name = "Header";
  header.resize(342, 48);
  header.x = 24;
  header.y = 52;
  header.fills = [];
  header.layoutMode = "HORIZONTAL";
  header.primaryAxisAlignItems = "SPACE_BETWEEN";
  header.counterAxisAlignItems = "CENTER";

  const brandGroup = figma.createFrame();
  brandGroup.layoutMode = "HORIZONTAL";
  brandGroup.counterAxisAlignItems = "CENTER";
  brandGroup.itemSpacing = 8;
  brandGroup.fills = [];
  const iceIcon = createText("❄️", 22, "Regular", C.secondary);
  const brandTitle = createText("SubZero", 22, "Bold", C.textPrimary);
  brandGroup.appendChild(iceIcon);
  brandGroup.appendChild(brandTitle);
  header.appendChild(brandGroup);

  const statsGroup = figma.createFrame();
  statsGroup.layoutMode = "HORIZONTAL";
  statsGroup.counterAxisAlignItems = "CENTER";
  statsGroup.itemSpacing = 8;
  statsGroup.fills = [];

  const quotaBadge = figma.createFrame();
  quotaBadge.layoutMode = "HORIZONTAL";
  quotaBadge.paddingLeft = 10;
  quotaBadge.paddingRight = 10;
  quotaBadge.paddingTop = 4;
  quotaBadge.paddingBottom = 4;
  quotaBadge.cornerRadius = 999;
  quotaBadge.fills = [solidPaint(C.surface)];
  quotaBadge.strokes = [solidPaint(C.surfaceVariant)];
  quotaBadge.appendChild(createText("14 / 25 usados", 11, "Medium", C.textSecondary));

  const proBadge = figma.createFrame();
  proBadge.layoutMode = "HORIZONTAL";
  proBadge.paddingLeft = 8;
  proBadge.paddingRight = 8;
  proBadge.paddingTop = 4;
  proBadge.paddingBottom = 4;
  proBadge.cornerRadius = 999;
  proBadge.fills = [solidPaint(C.goldBg)];
  proBadge.strokes = [solidPaint(C.gold)];
  proBadge.appendChild(createText("PRO ⭐", 11, "Bold", C.gold));

  statsGroup.appendChild(quotaBadge);
  statsGroup.appendChild(proBadge);
  header.appendChild(statsGroup);
  screen1.appendChild(header);

  // Filter Chips Row
  const chipsRow = figma.createFrame();
  chipsRow.name = "FilterChipsRow";
  chipsRow.resize(366, 36);
  chipsRow.x = 24;
  chipsRow.y = 114;
  chipsRow.fills = [];
  chipsRow.layoutMode = "HORIZONTAL";
  chipsRow.itemSpacing = 8;
  chipsRow.appendChild(createFilterChip("Todos (14)", true));
  chipsRow.appendChild(createFilterChip("Críticos (2)", false));
  chipsRow.appendChild(createFilterChip("Por vencer (4)", false));
  chipsRow.appendChild(createFilterChip("Seguros (8)", false));
  screen1.appendChild(chipsRow);

  // Lista de Items
  const itemsList = figma.createFrame();
  itemsList.name = "InventoryList";
  itemsList.resize(342, 540);
  itemsList.x = 24;
  itemsList.y = 166;
  itemsList.fills = [];
  itemsList.layoutMode = "VERTICAL";
  itemsList.itemSpacing = 12;

  itemsList.appendChild(createItemCard("🥩", "Bifes de lomo", "Cajón superior • 800g", "Vence en 4 días", C.critBg, C.critText));
  itemsList.appendChild(createItemCard("🍗", "Pechugas de pollo", "Bolsa Ziploc • 1.2kg", "Vence en 19 días", C.warnBg, C.warnText));
  itemsList.appendChild(createItemCard("🥬", "Espinaca congelada", "Estante 2 • Tupper", "Vence en 7 meses", C.safeBg, C.safeText));
  itemsList.appendChild(createItemCard("🍲", "Guiso de lentejas", "Cajón medio • 2 porc.", "Vence en 2 meses", C.safeBg, C.safeText));
  screen1.appendChild(itemsList);

  // FAB (+) Flotante
  const fab = figma.createFrame();
  fab.name = "FAB_Add";
  fab.resize(56, 56);
  fab.x = 310;
  fab.y = 690;
  fab.cornerRadius = 28;
  fab.fills = [solidPaint(C.secondary)];
  fab.layoutMode = "HORIZONTAL";
  fab.primaryAxisAlignItems = "CENTER";
  fab.counterAxisAlignItems = "CENTER";
  fab.effects = [{
    type: "DROP_SHADOW",
    color: { r: 0, g: 0, b: 0, a: 0.35 },
    offset: { x: 0, y: 6 },
    radius: 12,
    spread: 0,
    visible: true,
    blendMode: "NORMAL"
  }];
  fab.appendChild(createText("+", 28, "Bold", "#0A192F"));
  screen1.appendChild(fab);

  // Bottom Ad Banner
  const adBanner = figma.createFrame();
  adBanner.name = "AdBanner";
  adBanner.resize(320, 50);
  adBanner.x = 35;
  adBanner.y = 770;
  adBanner.cornerRadius = 8;
  adBanner.fills = [solidPaint(C.surface)];
  adBanner.strokes = [solidPaint(C.surfaceVariant)];
  adBanner.layoutMode = "HORIZONTAL";
  adBanner.primaryAxisAlignItems = "CENTER";
  adBanner.counterAxisAlignItems = "CENTER";
  adBanner.appendChild(createText("📢 Ad Placeholder (ironSource LevelPlay 320x50)", 11, "Regular", C.textSecondary));
  screen1.appendChild(adBanner);

  // =========================================================
  // PANTALLA 2: Quick-Add Modal / Bottom Sheet (390x844)
  // =========================================================
  const screen2 = figma.createFrame();
  screen2.name = "add_item_bottom_sheet";
  screen2.resize(390, 844);
  screen2.fills = [solidPaint("#050D18", 0.9)];
  screen2.clipsContent = true;

  // Bottom Sheet Modal
  const modal = figma.createFrame();
  modal.name = "ModalContainer";
  modal.resize(390, 720);
  modal.x = 0;
  modal.y = 124;
  modal.cornerRadius = 24;
  modal.fills = [solidPaint(C.bgDark)];
  modal.strokes = [solidPaint(C.surfaceVariant)];
  modal.strokeWeight = 1;
  modal.layoutMode = "VERTICAL";
  modal.paddingLeft = 24;
  modal.paddingRight = 24;
  modal.paddingTop = 16;
  modal.paddingBottom = 24;
  modal.itemSpacing = 16;

  // Drag handle
  const handleContainer = figma.createFrame();
  handleContainer.resize(342, 10);
  handleContainer.fills = [];
  handleContainer.layoutMode = "HORIZONTAL";
  handleContainer.primaryAxisAlignItems = "CENTER";
  const handle = figma.createFrame();
  handle.resize(40, 4);
  handle.cornerRadius = 2;
  handle.fills = [solidPaint(C.surfaceVariant)];
  handleContainer.appendChild(handle);
  modal.appendChild(handleContainer);

  // Modal Header
  const modalHeader = figma.createFrame();
  modalHeader.resize(342, 28);
  modalHeader.fills = [];
  modalHeader.layoutMode = "HORIZONTAL";
  modalHeader.primaryAxisAlignItems = "SPACE_BETWEEN";
  modalHeader.appendChild(createText("Congelar Alimento", 20, "Bold", C.textPrimary));
  modalHeader.appendChild(createText("✕", 18, "Regular", C.textSecondary));
  modal.appendChild(modalHeader);

  // Input: Nombre del alimento
  const nameInput = figma.createFrame();
  nameInput.resize(342, 52);
  nameInput.cornerRadius = 14;
  nameInput.fills = [solidPaint(C.surface)];
  nameInput.strokes = [solidPaint(C.surfaceVariant)];
  nameInput.layoutMode = "HORIZONTAL";
  nameInput.counterAxisAlignItems = "CENTER";
  nameInput.paddingLeft = 16;
  nameInput.paddingRight = 16;
  nameInput.appendChild(createText("Salmón rosado congelado", 14, "Regular", C.textPrimary));
  modal.appendChild(nameInput);

  // Selector de Categorías (Carrusel)
  const catLabel = createText("CATEGORÍA DE ALIMENTO", 11, "Semi Bold", C.textSecondary);
  modal.appendChild(catLabel);

  const catRow = figma.createFrame();
  catRow.resize(342, 68);
  catRow.fills = [];
  catRow.layoutMode = "HORIZONTAL";
  catRow.itemSpacing = 10;

  const cats = [
    { icon: "🥩", label: "Carnes", active: false },
    { icon: "🐟", label: "Pescados", active: true },
    { icon: "🍗", label: "Aves", active: false },
    { icon: "🥦", label: "Verduras", active: false },
    { icon: "🍲", label: "Cocidos", active: false }
  ];

  for (const cat of cats) {
    const catBox = figma.createFrame();
    catBox.resize(58, 64);
    catBox.cornerRadius = 14;
    catBox.layoutMode = "VERTICAL";
    catBox.primaryAxisAlignItems = "CENTER";
    catBox.counterAxisAlignItems = "CENTER";
    catBox.itemSpacing = 4;
    if (cat.active) {
      catBox.fills = [solidPaint(C.primary)];
      catBox.appendChild(createText(cat.icon, 20, "Regular", "#FFFFFF"));
      catBox.appendChild(createText(cat.label, 10, "Semi Bold", "#FFFFFF"));
    } else {
      catBox.fills = [solidPaint(C.surface)];
      catBox.strokes = [solidPaint(C.surfaceVariant)];
      catBox.appendChild(createText(cat.icon, 20, "Regular", C.textPrimary));
      catBox.appendChild(createText(cat.label, 10, "Regular", C.textSecondary));
    }
    catRow.appendChild(catBox);
  }
  modal.appendChild(catRow);

  // Card de Caducidad Sugerida Automática
  const autoDateCard = figma.createFrame();
  autoDateCard.resize(342, 70);
  autoDateCard.cornerRadius = 14;
  autoDateCard.fills = [solidPaint("#0C2B35")];
  autoDateCard.strokes = [solidPaint(C.safeText)];
  autoDateCard.layoutMode = "HORIZONTAL";
  autoDateCard.primaryAxisAlignItems = "SPACE_BETWEEN";
  autoDateCard.counterAxisAlignItems = "CENTER";
  autoDateCard.paddingLeft = 14;
  autoDateCard.paddingRight = 14;

  const dateInfo = figma.createFrame();
  dateInfo.layoutMode = "VERTICAL";
  dateInfo.itemSpacing = 4;
  dateInfo.fills = [];
  dateInfo.appendChild(createText("⚡ Caducidad sugerida automáticamente", 11, "Medium", C.safeText));
  dateInfo.appendChild(createText("+8 meses (15 Oct 2026)", 14, "Bold", C.textPrimary));
  autoDateCard.appendChild(dateInfo);

  const editBtn = createText("Cambiar", 12, "Semi Bold", C.secondary);
  autoDateCard.appendChild(editBtn);
  modal.appendChild(autoDateCard);

  // SwitchListTile estilizado
  const switchRow = figma.createFrame();
  switchRow.resize(342, 54);
  switchRow.cornerRadius = 14;
  switchRow.fills = [solidPaint(C.surface)];
  switchRow.layoutMode = "HORIZONTAL";
  switchRow.primaryAxisAlignItems = "SPACE_BETWEEN";
  switchRow.counterAxisAlignItems = "CENTER";
  switchRow.paddingLeft = 16;
  switchRow.paddingRight = 16;

  const switchLabelCol = figma.createFrame();
  switchLabelCol.layoutMode = "VERTICAL";
  switchLabelCol.itemSpacing = 2;
  switchLabelCol.fills = [];
  switchLabelCol.appendChild(createText("Recordarme antes de vencer", 13, "Semi Bold", C.textPrimary));
  switchLabelCol.appendChild(createText("Alerta diaria a las 09:00 AM", 11, "Regular", C.textSecondary));
  switchRow.appendChild(switchLabelCol);

  const toggleSwitch = figma.createFrame();
  toggleSwitch.resize(44, 26);
  toggleSwitch.cornerRadius = 13;
  toggleSwitch.fills = [solidPaint(C.secondary)];
  toggleSwitch.layoutMode = "HORIZONTAL";
  toggleSwitch.primaryAxisAlignItems = "MAX";
  toggleSwitch.counterAxisAlignItems = "CENTER";
  toggleSwitch.paddingRight = 3;
  const toggleThumb = figma.createFrame();
  toggleThumb.resize(20, 20);
  toggleThumb.cornerRadius = 10;
  toggleThumb.fills = [solidPaint(C.bgDark)];
  toggleSwitch.appendChild(toggleThumb);
  switchRow.appendChild(toggleSwitch);
  modal.appendChild(switchRow);

  // Input Notas
  const notesInput = figma.createFrame();
  notesInput.resize(342, 48);
  notesInput.cornerRadius = 14;
  notesInput.fills = [solidPaint(C.surface)];
  notesInput.strokes = [solidPaint(C.surfaceVariant)];
  notesInput.layoutMode = "HORIZONTAL";
  notesInput.counterAxisAlignItems = "CENTER";
  notesInput.paddingLeft = 16;
  notesInput.appendChild(createText("Ubicación: Tupper azul, Cajón 2", 13, "Regular", C.textSecondary));
  modal.appendChild(notesInput);

  // Botón Guardar
  modal.appendChild(createPrimaryButton("Guardar en el congelador"));
  screen2.appendChild(modal);

  // =========================================================
  // PANTALLA 3: Paywall SubZero Pro (390x844)
  // =========================================================
  const screen3 = figma.createFrame();
  screen3.name = "paywall_screen";
  screen3.resize(390, 844);
  screen3.fills = [solidPaint(C.bgDark)];
  screen3.clipsContent = true;

  screen3.appendChild(createStatusBar());

  // Close button
  const closeBtn = figma.createFrame();
  closeBtn.resize(36, 36);
  closeBtn.x = 24;
  closeBtn.y = 52;
  closeBtn.cornerRadius = 18;
  closeBtn.fills = [solidPaint(C.surface)];
  closeBtn.layoutMode = "HORIZONTAL";
  closeBtn.primaryAxisAlignItems = "CENTER";
  closeBtn.counterAxisAlignItems = "CENTER";
  closeBtn.appendChild(createText("✕", 16, "Regular", C.textSecondary));
  screen3.appendChild(closeBtn);

  // Hero Section
  const heroGroup = figma.createFrame();
  heroGroup.resize(342, 210);
  heroGroup.x = 24;
  heroGroup.y = 96;
  heroGroup.fills = [];
  heroGroup.layoutMode = "VERTICAL";
  heroGroup.primaryAxisAlignItems = "CENTER";
  heroGroup.counterAxisAlignItems = "CENTER";
  heroGroup.itemSpacing = 12;

  // Iceberg Halo
  const halo = figma.createFrame();
  halo.resize(96, 96);
  halo.cornerRadius = 48;
  halo.fills = [solidPaint("#0C2B35")];
  halo.strokes = [solidPaint(C.secondary)];
  halo.strokeWeight = 2;
  halo.layoutMode = "HORIZONTAL";
  halo.primaryAxisAlignItems = "CENTER";
  halo.counterAxisAlignItems = "CENTER";
  halo.appendChild(createText("🏔️", 44, "Regular", C.secondary));
  heroGroup.appendChild(halo);

  heroGroup.appendChild(createText("Desbloquea SubZero Pro", 24, "Bold", C.textPrimary));
  const subHero = createText("Espacio ilimitado y tranquilidad total en tu cocina", 14, "Regular", C.textSecondary);
  subHero.textAlignHorizontal = "CENTER";
  heroGroup.appendChild(subHero);
  screen3.appendChild(heroGroup);

  // Lista de Beneficios
  const benefitsCol = figma.createFrame();
  benefitsCol.name = "BenefitsList";
  benefitsCol.resize(342, 160);
  benefitsCol.x = 24;
  benefitsCol.y = 320;
  benefitsCol.fills = [solidPaint(C.surface)];
  benefitsCol.strokes = [solidPaint(C.surfaceVariant)];
  benefitsCol.cornerRadius = 18;
  benefitsCol.layoutMode = "VERTICAL";
  benefitsCol.paddingLeft = 20;
  benefitsCol.paddingRight = 20;
  benefitsCol.paddingTop = 16;
  benefitsCol.paddingBottom = 16;
  benefitsCol.itemSpacing = 16;

  const benefits = [
    "Alimentos ilimitados (elimina el tope de 25)",
    "100% libre de anuncios para siempre",
    "Apoyo directo a un desarrollador independiente"
  ];

  for (const b of benefits) {
    const row = figma.createFrame();
    row.resize(302, 24);
    row.fills = [];
    row.layoutMode = "HORIZONTAL";
    row.counterAxisAlignItems = "CENTER";
    row.itemSpacing = 12;

    const check = createText("✓", 16, "Bold", C.secondary);
    const label = createText(b, 13, "Medium", C.textPrimary);
    row.appendChild(check);
    row.appendChild(label);
    benefitsCol.appendChild(row);
  }
  screen3.appendChild(benefitsCol);

  // Tarjeta de Oferta Destacada
  const offerCard = figma.createFrame();
  offerCard.name = "LifetimeOfferCard";
  offerCard.resize(342, 90);
  offerCard.x = 24;
  offerCard.y = 500;
  offerCard.cornerRadius = 18;
  offerCard.fills = [solidPaint(C.surface)];
  offerCard.strokes = [solidPaint(C.secondary)];
  offerCard.strokeWeight = 2;
  offerCard.layoutMode = "HORIZONTAL";
  offerCard.primaryAxisAlignItems = "SPACE_BETWEEN";
  offerCard.counterAxisAlignItems = "CENTER";
  offerCard.paddingLeft = 20;
  offerCard.paddingRight = 20;

  const offerInfo = figma.createFrame();
  offerInfo.layoutMode = "VERTICAL";
  offerInfo.itemSpacing = 4;
  offerInfo.fills = [];

  const tag = figma.createFrame();
  tag.paddingLeft = 8;
  tag.paddingRight = 8;
  tag.paddingTop = 2;
  tag.paddingBottom = 2;
  tag.cornerRadius = 999;
  tag.fills = [solidPaint(C.goldBg)];
  tag.appendChild(createText("UN SOLO PAGO", 10, "Bold", C.gold));
  offerInfo.appendChild(tag);
  offerInfo.appendChild(createText("Acceso Vitalicio Único", 16, "Semi Bold", C.textPrimary));
  offerCard.appendChild(offerInfo);

  const priceTag = createText("$3.99 USD", 22, "Bold", C.secondary);
  offerCard.appendChild(priceTag);
  screen3.appendChild(offerCard);

  // Botón Continuar
  const payBtn = createPrimaryButton("Continuar a SubZero Pro");
  payBtn.x = 24;
  payBtn.y = 614;
  screen3.appendChild(payBtn);

  // Restore Purchases
  const restoreTxt = createText("Restaurar compras", 13, "Regular", C.textSecondary);
  restoreTxt.x = 145;
  restoreTxt.y = 684;
  screen3.appendChild(restoreTxt);

  // Terminos y privacidad
  const termsTxt = createText("Sin suscripciones recurrentes • Pago seguro con Google Play", 11, "Regular", "#5A6785");
  termsTxt.x = 35;
  termsTxt.y = 716;
  screen3.appendChild(termsTxt);

  // =========================================================
  // POSICIONAMIENTO EN CANVAS (40px de separación horizontal)
  // =========================================================
  screen1.x = 0;
  screen1.y = 0;

  screen2.x = 390 + 40; // 430
  screen2.y = 0;

  screen3.x = (390 + 40) * 2; // 860
  screen3.y = 0;

  // Añadir a la página actual y enfocar
  figma.currentPage.appendChild(screen1);
  figma.currentPage.appendChild(screen2);
  figma.currentPage.appendChild(screen3);

  figma.viewport.scrollAndZoomIntoView([screen1, screen2, screen3]);
  figma.notify("✨ ¡Diseño móvil de SubZero generado con éxito en Figma!");
})();

