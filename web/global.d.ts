interface Window {
  webkit: {
    messageHandlers: {
      embrace: {
        postMessage(body: unknown): void;
      };
    };
  };
}
