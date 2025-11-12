#!/usr/bin/env node
/**
 * Generate NowPlaying for Plex app icons
 * Creates landscape (192×128 base size) icons in all required macOS sizes
 */

const { createCanvas } = require('canvas');
const fs = require('fs');
const path = require('path');

const colors = { orange: '#FF6B35', yellow: '#FFC93C', white: '#FFFFFF' };

function createGradient(ctx, x, y, width, height) {
    // Diagonal gradient from top-left to bottom-right
    const gradient = ctx.createLinearGradient(x, y, x + width, y + height);
    // More orange, less yellow: Orange dominant until 75%
    gradient.addColorStop(0, colors.orange);      // #FF6B35 Orange (top-left)
    gradient.addColorStop(0.75, '#FFAB3B');       // 50/50 blend (pushed way right)
    gradient.addColorStop(1, colors.yellow);      // #FFC93C Yellow (bottom-right corner only)
    return gradient;
}

function roundRect(ctx, x, y, width, height, radius) {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + width - radius, y);
    ctx.arcTo(x + width, y, x + width, y + radius, radius);
    ctx.lineTo(x + width, y + height - radius);
    ctx.arcTo(x + width, y + height, x + width - radius, y + height, radius);
    ctx.lineTo(x + radius, y + height);
    ctx.arcTo(x, y + height, x, y + height - radius, radius);
    ctx.lineTo(x, y + radius);
    ctx.arcTo(x, y, x + radius, y, radius);
    ctx.closePath();
}

function drawIcon(canvas, squareSize) {
    const ctx = canvas.getContext('2d');

    // Clear canvas with transparency
    ctx.clearRect(0, 0, squareSize, squareSize);

    // Calculate landscape dimensions maintaining 3:2 aspect ratio
    const landscapeHeight = squareSize * (2 / 3);
    const landscapeWidth = landscapeHeight * 1.5;

    // Center the landscape icon in the square
    const offsetX = (squareSize - landscapeWidth) / 2;
    const offsetY = (squareSize - landscapeHeight) / 2;

    // Save context for offset
    ctx.save();
    ctx.translate(offsetX, offsetY);

    const padding = Math.max(2, Math.min(landscapeWidth, landscapeHeight) * 0.08);
    const cornerRadius = Math.max(2, Math.min(landscapeWidth, landscapeHeight) * 0.08);

    // Draw white/light background
    ctx.fillStyle = colors.white;
    roundRect(ctx, padding, padding, landscapeWidth - padding * 2, landscapeHeight - padding * 2, cornerRadius);
    ctx.fill();

    // Create composite path with holes for equalizer bars
    const numBars = 7;
    const barAreaWidth = (landscapeWidth - padding * 2) * 0.6;
    const barAreaX = padding + (landscapeWidth - padding * 2 - barAreaWidth) / 2;
    const barSpacing = barAreaWidth / numBars;
    const barWidth = barSpacing * 0.5;
    const maxBarHeight = (landscapeHeight - padding * 2) * 0.6;
    const heights = [0.7, 0.9, 0.5, 0.8, 0.6, 0.85, 0.55];

    // Start composite path with background rectangle
    ctx.globalCompositeOperation = 'destination-out';

    // Cut out equalizer bars
    for (let i = 0; i < numBars; i++) {
        const barHeight = maxBarHeight * heights[i % heights.length];
        const x = barAreaX + i * barSpacing;
        const y = padding + ((landscapeHeight - padding * 2) - barHeight) / 2;

        roundRect(ctx, x, y, barWidth, barHeight, barWidth / 4);
        ctx.fill();
    }

    // Cut out chevron badge - circle with chevron in middle
    const badgeSize = Math.min(landscapeWidth, landscapeHeight) * 0.25;
    const badgeX = landscapeWidth - padding - badgeSize * 0.7;
    const badgeY = landscapeHeight - padding - badgeSize * 0.7;

    // Cut out circle
    ctx.beginPath();
    ctx.arc(badgeX, badgeY, badgeSize * 0.5, 0, Math.PI * 2);
    ctx.fill();

    // Reset to draw chevron in the cutout
    ctx.globalCompositeOperation = 'source-over';

    // Draw chevron inside the cutout circle
    const scale = badgeSize * 0.015;
    const chevronCenterX = 118.15;
    const chevronCenterY = 33.85;

    ctx.save();
    ctx.translate(badgeX, badgeY);
    ctx.scale(scale, scale);
    ctx.translate(-chevronCenterX + 1, -chevronCenterY);

    ctx.fillStyle = colors.white;
    ctx.beginPath();
    ctx.moveTo(117.9, 33.9);
    ctx.lineTo(104.1, 13.5);
    ctx.lineTo(118.3, 13.5);
    ctx.lineTo(132.0, 33.9);
    ctx.lineTo(118.3, 54.2);
    ctx.lineTo(104.1, 54.2);
    ctx.closePath();
    ctx.fill();

    ctx.restore();

    // Return to normal mode
    ctx.globalCompositeOperation = 'source-over';

    // Restore context after landscape drawing
    ctx.restore();
}

function drawDriveIcon(canvas, size) {
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, size, size);

    // Scale factor for consistent proportions
    const scale = size / 512;

    // Draw 3D hard drive body
    const driveWidth = 380 * scale;
    const driveHeight = 280 * scale;
    const driveDepth = 40 * scale;
    const driveX = (size - driveWidth) / 2;
    const driveY = size * 0.55 - driveHeight / 2;
    const cornerRadius = 20 * scale;

    // Shadow
    ctx.save();
    ctx.shadowColor = 'rgba(0, 0, 0, 0.3)';
    ctx.shadowBlur = 30 * scale;
    ctx.shadowOffsetY = 15 * scale;

    // Front face - main gradient (light gray metallic)
    const frontGradient = ctx.createLinearGradient(driveX, driveY, driveX, driveY + driveHeight);
    frontGradient.addColorStop(0, '#E8E8E8');
    frontGradient.addColorStop(0.5, '#D0D0D0');
    frontGradient.addColorStop(1, '#B8B8B8');
    ctx.fillStyle = frontGradient;
    roundRect(ctx, driveX, driveY, driveWidth, driveHeight, cornerRadius);
    ctx.fill();

    ctx.restore();

    // Top edge (3D depth effect)
    ctx.save();
    ctx.beginPath();
    ctx.moveTo(driveX + cornerRadius, driveY);
    ctx.lineTo(driveX + driveWidth - cornerRadius, driveY);
    ctx.lineTo(driveX + driveWidth - cornerRadius + driveDepth * 0.5, driveY - driveDepth * 0.8);
    ctx.lineTo(driveX + cornerRadius + driveDepth * 0.5, driveY - driveDepth * 0.8);
    ctx.closePath();

    const topGradient = ctx.createLinearGradient(0, driveY - driveDepth, 0, driveY);
    topGradient.addColorStop(0, '#F5F5F5');
    topGradient.addColorStop(1, '#E0E0E0');
    ctx.fillStyle = topGradient;
    ctx.fill();
    ctx.restore();

    // Right edge (3D depth effect)
    ctx.save();
    ctx.beginPath();
    ctx.moveTo(driveX + driveWidth, driveY + cornerRadius);
    ctx.lineTo(driveX + driveWidth, driveY + driveHeight - cornerRadius);
    ctx.lineTo(driveX + driveWidth + driveDepth * 0.5, driveY + driveHeight - cornerRadius - driveDepth * 0.3);
    ctx.lineTo(driveX + driveWidth + driveDepth * 0.5, driveY + cornerRadius - driveDepth * 0.3);
    ctx.closePath();

    const rightGradient = ctx.createLinearGradient(driveX + driveWidth, 0, driveX + driveWidth + driveDepth, 0);
    rightGradient.addColorStop(0, '#C0C0C0');
    rightGradient.addColorStop(1, '#A0A0A0');
    ctx.fillStyle = rightGradient;
    ctx.fill();
    ctx.restore();

    // Front face border for definition
    ctx.strokeStyle = 'rgba(0, 0, 0, 0.15)';
    ctx.lineWidth = 2 * scale;
    roundRect(ctx, driveX, driveY, driveWidth, driveHeight, cornerRadius);
    ctx.stroke();

    // Add metallic highlights
    ctx.save();
    const highlight = ctx.createLinearGradient(driveX, driveY, driveX, driveY + driveHeight * 0.3);
    highlight.addColorStop(0, 'rgba(255, 255, 255, 0.4)');
    highlight.addColorStop(1, 'rgba(255, 255, 255, 0)');
    ctx.fillStyle = highlight;
    roundRect(ctx, driveX + 5 * scale, driveY + 5 * scale, driveWidth - 10 * scale, driveHeight * 0.3, cornerRadius);
    ctx.fill();
    ctx.restore();

    // LED indicator light (small green dot, top right area)
    const ledX = driveX + driveWidth - 40 * scale;
    const ledY = driveY + 30 * scale;
    const ledRadius = 6 * scale;

    ctx.save();
    const ledGradient = ctx.createRadialGradient(ledX, ledY, 0, ledX, ledY, ledRadius);
    ledGradient.addColorStop(0, '#80FF80');
    ledGradient.addColorStop(0.7, '#40C040');
    ledGradient.addColorStop(1, '#208020');
    ctx.fillStyle = ledGradient;
    ctx.beginPath();
    ctx.arc(ledX, ledY, ledRadius, 0, Math.PI * 2);
    ctx.fill();

    // LED glow
    ctx.shadowColor = '#40FF40';
    ctx.shadowBlur = 10 * scale;
    ctx.beginPath();
    ctx.arc(ledX, ledY, ledRadius * 0.6, 0, Math.PI * 2);
    ctx.fillStyle = '#A0FFA0';
    ctx.fill();
    ctx.restore();

    // Now draw the landscape logo on top of the drive
    // Make it slightly smaller to fit nicely on the drive face
    const logoScale = 0.6;
    const logoHeight = driveHeight * logoScale;
    const logoWidth = logoHeight * 1.5; // 3:2 ratio
    const logoX = driveX + (driveWidth - logoWidth) / 2;
    const logoY = driveY + (driveHeight - logoHeight) / 2 + 10 * scale; // Slightly lower for better visual balance

    // Draw logo with slight 3D effect
    ctx.save();
    ctx.shadowColor = 'rgba(0, 0, 0, 0.3)';
    ctx.shadowBlur = 10 * scale;
    ctx.shadowOffsetY = 3 * scale;

    const logoPadding = logoHeight * 0.08;
    const logoCornerRadius = logoHeight * 0.12;

    // Logo background with gradient
    const logoGradient = createGradient(ctx, logoX + logoPadding, logoY + logoPadding,
                                        logoWidth - logoPadding * 2, logoHeight - logoPadding * 2);
    ctx.fillStyle = logoGradient;
    roundRect(ctx, logoX + logoPadding, logoY + logoPadding,
              logoWidth - logoPadding * 2, logoHeight - logoPadding * 2, logoCornerRadius);
    ctx.fill();

    // Draw equalizer bars
    const numBars = 5;
    const barSpacing = (logoWidth - logoPadding * 2) / (numBars + 1);
    const barWidth = barSpacing * 0.4;
    const maxBarHeight = (logoHeight - logoPadding * 2) * 0.7;
    const barHeights = [0.5, 0.8, 1.0, 0.7, 0.6];

    ctx.fillStyle = colors.white;
    for (let i = 0; i < numBars; i++) {
        const x = logoX + logoPadding + barSpacing * (i + 1) - barWidth / 2;
        const barHeight = maxBarHeight * barHeights[i];
        const y = logoY + logoHeight - logoPadding - barHeight - logoPadding * 0.5;
        roundRect(ctx, x, y, barWidth, barHeight, barWidth / 4);
        ctx.fill();
    }

    // Draw Plex chevron badge
    const badgeSize = logoHeight * 0.28;
    const badgeX = logoX + logoWidth - logoPadding - badgeSize * 0.65;
    const badgeY = logoY + logoPadding + badgeSize * 0.65;

    // Badge circle background
    ctx.fillStyle = colors.white;
    ctx.beginPath();
    ctx.arc(badgeX, badgeY, badgeSize * 0.5, 0, Math.PI * 2);
    ctx.fill();

    // Plex chevron (orange)
    const chevronSize = badgeSize * 0.35;
    ctx.fillStyle = colors.orange;
    ctx.beginPath();
    ctx.moveTo(badgeX - chevronSize * 0.3, badgeY - chevronSize * 0.5);
    ctx.lineTo(badgeX + chevronSize * 0.4, badgeY);
    ctx.lineTo(badgeX - chevronSize * 0.3, badgeY + chevronSize * 0.5);
    ctx.lineTo(badgeX - chevronSize * 0.1, badgeY + chevronSize * 0.5);
    ctx.lineTo(badgeX + chevronSize * 0.6, badgeY);
    ctx.lineTo(badgeX - chevronSize * 0.1, badgeY - chevronSize * 0.5);
    ctx.closePath();
    ctx.fill();

    ctx.restore();
}

// macOS requires these specific sizes for AppIcon.appiconset
// Using square format with landscape logo centered inside
const sizes = [
    { name: 'icon_16x16', size: 16 },        // 16pt @1x
    { name: 'icon_16x16@2x', size: 32 },     // 16pt @2x
    { name: 'icon_32x32', size: 32 },        // 32pt @1x
    { name: 'icon_32x32@2x', size: 64 },     // 32pt @2x
    { name: 'icon_128x128', size: 128 },     // 128pt @1x
    { name: 'icon_128x128@2x', size: 256 },  // 128pt @2x
    { name: 'icon_256x256', size: 256 },     // 256pt @1x
    { name: 'icon_256x256@2x', size: 512 },  // 256pt @2x
    { name: 'icon_512x512', size: 512 },     // 512pt @1x
    { name: 'icon_512x512@2x', size: 1024 }  // 512pt @2x
];

const outputDir = path.join(__dirname, 'PlexWidget', 'PlexWidget', 'Assets.xcassets', 'AppIcon.appiconset');

console.log('Generating NowPlaying for Plex icons...\n');

sizes.forEach(({ name, size }) => {
    console.log(`Creating ${name}.png (${size}×${size})`);

    const canvas = createCanvas(size, size);
    drawIcon(canvas, size);

    const buffer = canvas.toBuffer('image/png');
    const outputPath = path.join(outputDir, `${name}.png`);
    fs.writeFileSync(outputPath, buffer);
});

console.log('\n✅ All icon sizes generated successfully!');
console.log(`📁 Output directory: ${outputDir}`);

// Generate DMG volume icon (3D drive with logo)
console.log('\n🔨 Generating DMG volume icon...\n');
const dmgSizes = [
    { name: 'dmg-icon_16x16', size: 16 },
    { name: 'dmg-icon_32x32', size: 32 },
    { name: 'dmg-icon_128x128', size: 128 },
    { name: 'dmg-icon_256x256', size: 256 },
    { name: 'dmg-icon_512x512', size: 512 },
];

const dmgOutputDir = path.join(__dirname, 'PlexWidget');

dmgSizes.forEach(({ name, size }) => {
    console.log(`Creating ${name}.png (${size}×${size})`);

    const canvas = createCanvas(size, size);
    drawDriveIcon(canvas, size);

    const buffer = canvas.toBuffer('image/png');
    const outputPath = path.join(dmgOutputDir, `${name}.png`);
    fs.writeFileSync(outputPath, buffer);
});

console.log('\n✅ DMG icon PNGs generated!');
console.log(`📁 DMG icons: ${dmgOutputDir}/dmg-icon_*.png`);
console.log('\n🔧 Now converting to .icns format...');
