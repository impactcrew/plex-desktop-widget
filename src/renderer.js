const PlexAPI = require('./plex-api');
const fs = require('fs');
const path = require('path');

let plexAPI = null;
let updateInterval = null;
let currentSession = null;

// DOM elements
const loadingEl = document.getElementById('loading');
const nowPlayingEl = document.getElementById('nowPlaying');
const notPlayingEl = document.getElementById('notPlaying');
const albumArtEl = document.getElementById('albumArt');
const trackTitleEl = document.getElementById('trackTitle');
const artistNameEl = document.getElementById('artistName');
const albumNameEl = document.getElementById('albumName');
const progressFillEl = document.getElementById('progressFill');
const timeDisplayEl = document.getElementById('timeDisplay');
const playPauseBtnEl = document.getElementById('playPauseBtn');
const prevBtnEl = document.getElementById('prevBtn');
const nextBtnEl = document.getElementById('nextBtn');

function showLoading() {
  loadingEl.style.display = 'flex';
  nowPlayingEl.style.display = 'none';
  notPlayingEl.style.display = 'none';
}

function showNowPlaying() {
  loadingEl.style.display = 'none';
  nowPlayingEl.style.display = 'flex';
  notPlayingEl.style.display = 'none';
}

function showNotPlaying() {
  loadingEl.style.display = 'none';
  nowPlayingEl.style.display = 'none';
  notPlayingEl.style.display = 'block';
}

function formatTime(ms) {
  const seconds = Math.floor(ms / 1000);
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

function updateScrollingText(element, text) {
  const containerWidth = element.offsetWidth;
  element.innerHTML = ''; // Clear existing content

  // Create a temporary span to measure text width
  const tempSpan = document.createElement('span');
  tempSpan.style.visibility = 'hidden';
  tempSpan.style.position = 'absolute';
  tempSpan.textContent = text;
  document.body.appendChild(tempSpan);
  const textWidth = tempSpan.offsetWidth;
  document.body.removeChild(tempSpan);

  if (textWidth > containerWidth) {
    // Text is too long, enable scrolling
    element.classList.add('scrolling');
    const innerSpan = document.createElement('span');
    innerSpan.className = 'track-title-inner';
    innerSpan.textContent = text + ' • ' + text; // Duplicate for seamless loop
    element.appendChild(innerSpan);
  } else {
    // Text fits, no scrolling needed
    element.classList.remove('scrolling');
    element.textContent = text;
  }
}

async function updateNowPlaying() {
  if (!plexAPI) {
    showLoading();
    return;
  }

  try {
    const nowPlaying = await plexAPI.getNowPlaying();

    if (nowPlaying) {
      currentSession = nowPlaying;

      // Update track title with scrolling
      updateScrollingText(trackTitleEl, nowPlaying.title);

      artistNameEl.textContent = nowPlaying.artist;
      albumNameEl.textContent = nowPlaying.album;

      // Update progress bar and time
      if (nowPlaying.duration && nowPlaying.viewOffset !== undefined) {
        const progress = (nowPlaying.viewOffset / nowPlaying.duration) * 100;
        progressFillEl.style.width = `${progress}%`;
        timeDisplayEl.textContent = `${formatTime(nowPlaying.viewOffset)} / ${formatTime(nowPlaying.duration)}`;
      } else {
        progressFillEl.style.width = '0%';
        timeDisplayEl.textContent = '0:00 / 0:00';
      }

      // Update play/pause button
      if (nowPlaying.state === 'paused') {
        playPauseBtnEl.textContent = '▶';
      } else {
        playPauseBtnEl.textContent = '⏸';
      }

      if (nowPlaying.albumArt) {
        albumArtEl.src = nowPlaying.albumArt;
        albumArtEl.style.display = 'block';
      } else {
        albumArtEl.style.display = 'none';
      }

      showNowPlaying();
    } else {
      currentSession = null;
      showNotPlaying();
    }
  } catch (error) {
    console.error('Error updating now playing:', error);
    showNotPlaying();
  }
}

function loadConfig() {
  const configPath = path.join(__dirname, '..', 'config.json');

  try {
    if (!fs.existsSync(configPath)) {
      console.error('config.json not found. Please create it with your Plex server details.');
      loadingEl.querySelector('span').textContent = 'Config file not found';
      return false;
    }

    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

    if (!config.plexServerUrl || !config.plexToken) {
      console.error('Invalid config.json. Please provide plexServerUrl and plexToken.');
      loadingEl.querySelector('span').textContent = 'Invalid config';
      return false;
    }

    plexAPI = new PlexAPI(config.plexServerUrl, config.plexToken);
    return true;
  } catch (error) {
    console.error('Error loading config:', error);
    loadingEl.querySelector('span').textContent = 'Config error';
    return false;
  }
}

// Control button handlers
playPauseBtnEl.addEventListener('click', async () => {
  if (!currentSession) return;

  if (currentSession.state === 'paused') {
    await plexAPI.play(currentSession);
  } else {
    await plexAPI.pause(currentSession);
  }

  // Immediate update to reflect change
  setTimeout(updateNowPlaying, 500);
});

prevBtnEl.addEventListener('click', async () => {
  if (!currentSession) return;
  await plexAPI.skipPrevious(currentSession);
  setTimeout(updateNowPlaying, 500);
});

nextBtnEl.addEventListener('click', async () => {
  if (!currentSession) return;
  await plexAPI.skipNext(currentSession);
  setTimeout(updateNowPlaying, 500);
});

// Initialize
function init() {
  showLoading();

  if (loadConfig()) {
    // Initial update
    updateNowPlaying();

    // Update every 2 seconds
    updateInterval = setInterval(updateNowPlaying, 2000);
  }
}

// Start the app
init();

// Cleanup on window close
window.addEventListener('beforeunload', () => {
  if (updateInterval) {
    clearInterval(updateInterval);
  }
});
