const axios = require('axios');

class PlexAPI {
  constructor(serverUrl, token) {
    this.serverUrl = serverUrl;
    this.token = token;
    this.clientIdentifier = 'plex-desktop-widget-' + Date.now();
    this.commandID = 0;
  }

  async getSessions() {
    try {
      const response = await axios.get(`${this.serverUrl}/status/sessions`, {
        headers: {
          'X-Plex-Token': this.token,
          'X-Plex-Client-Identifier': this.clientIdentifier,
          'Accept': 'application/json'
        },
        timeout: 5000
      });

      return response.data;
    } catch (error) {
      console.error('Error fetching Plex sessions:', error.message);
      return null;
    }
  }

  async getNowPlaying() {
    const sessions = await this.getSessions();

    if (!sessions || !sessions.MediaContainer || !sessions.MediaContainer.Metadata) {
      return null;
    }

    const tracks = sessions.MediaContainer.Metadata;

    // Filter for music tracks that are currently playing
    const playingMusic = tracks.find(track =>
      track.type === 'track' &&
      (track.Player?.state === 'playing' || track.Player?.state === 'paused')
    );

    if (!playingMusic) {
      return null;
    }

    // Get album art URL
    let albumArtUrl = null;
    if (playingMusic.thumb) {
      albumArtUrl = `${this.serverUrl}${playingMusic.thumb}?X-Plex-Token=${this.token}`;
    } else if (playingMusic.parentThumb) {
      albumArtUrl = `${this.serverUrl}${playingMusic.parentThumb}?X-Plex-Token=${this.token}`;
    } else if (playingMusic.grandparentThumb) {
      albumArtUrl = `${this.serverUrl}${playingMusic.grandparentThumb}?X-Plex-Token=${this.token}`;
    }

    return {
      title: playingMusic.title || 'Unknown Track',
      artist: playingMusic.grandparentTitle || playingMusic.originalTitle || 'Unknown Artist',
      album: playingMusic.parentTitle || 'Unknown Album',
      albumArt: albumArtUrl,
      state: playingMusic.Player?.state || 'playing',
      duration: playingMusic.duration,
      viewOffset: playingMusic.viewOffset,
      machineIdentifier: playingMusic.Player?.machineIdentifier,
      sessionKey: playingMusic.sessionKey || playingMusic.Session?.id,
      playerAddress: playingMusic.Player?.address,
      playerPort: playingMusic.Player?.port,
      playerProtocol: playingMusic.Player?.protocol
    };
  }

  async sendPlayerCommand(command, sessionData) {
    if (!sessionData || !sessionData.playerAddress) {
      console.error('No player address available');
      return false;
    }

    try {
      // Plex Media Player listens on port 3005 for remote control
      this.commandID++;
      const playerUrl = `http://${sessionData.playerAddress}:3005/player/playback/${command}`;

      console.log(`PLAYER CONTROL - Sending ${command} to ${playerUrl}`);

      const response = await axios.get(playerUrl, {
        params: {
          commandID: this.commandID
        },
        headers: {
          'X-Plex-Client-Identifier': this.clientIdentifier,
          'X-Plex-Device-Name': 'Plex Desktop Widget'
        },
        timeout: 5000
      });

      console.log(`${command} command sent successfully`);
      return true;
    } catch (error) {
      console.error(`Error sending ${command} command:`, error.message);
      return false;
    }
  }

  async play(sessionData) {
    return this.sendPlayerCommand('play', sessionData);
  }

  async pause(sessionData) {
    return this.sendPlayerCommand('pause', sessionData);
  }

  async skipNext(sessionData) {
    return this.sendPlayerCommand('skipNext', sessionData);
  }

  async skipPrevious(sessionData) {
    return this.sendPlayerCommand('skipPrevious', sessionData);
  }
}

module.exports = PlexAPI;
