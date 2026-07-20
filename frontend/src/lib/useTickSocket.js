import { useEffect, useRef } from "react";
import { Client } from "@stomp/stompjs";
import { wsBaseUrl } from "./config";

export function useTickSocket(sessionId, onTick) {
  const onTickRef = useRef(onTick);
  onTickRef.current = onTick;

  useEffect(() => {
    if (!sessionId) return undefined;

    const client = new Client({
      brokerURL: `${wsBaseUrl()}/ws`,
      reconnectDelay: 2000,
      onConnect: () => {
        client.subscribe(`/topic/sessions/${sessionId}/ticks`, (message) => {
          try {
            onTickRef.current(JSON.parse(message.body));
          } catch {
            // ignore malformed frame
          }
        });
      },
    });
    client.activate();

    return () => {
      client.deactivate();
    };
  }, [sessionId]);
}
