import { useState, useEffect } from 'react';

interface NetworkStatus {
  isOnline: boolean;
  lastChanged: Date | null;
}

export const useNetworkStatus = () => {
  const [networkStatus, setNetworkStatus] = useState<NetworkStatus>({
    isOnline: navigator.onLine,
    lastChanged: null,
  });

  useEffect(() => {
    const handleOnline = () => {
      setNetworkStatus({
        isOnline: true,
        lastChanged: new Date(),
      });
    };

    const handleOffline = () => {
      setNetworkStatus({
        isOnline: false,
        lastChanged: new Date(),
      });
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return networkStatus;
}; 