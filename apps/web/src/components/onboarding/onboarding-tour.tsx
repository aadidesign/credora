"use client";

import { useState, useEffect } from "react";
import Joyride, { CallBackProps, STATUS, Step } from "react-joyride";
import { useTheme } from "next-themes";

const TOUR_STORAGE_KEY = "credora-onboarding-completed";

const steps: Step[] = [
  {
    target: "body",
    content: (
      <div>
        <h3 className="font-bold text-lg mb-2">Welcome to Credora! 🎉</h3>
        <p>
          Credora is a decentralized credit scoring protocol. Let&apos;s take a quick
          tour to help you get started.
        </p>
      </div>
    ),
    placement: "center",
    disableBeacon: true,
  },
  {
    target: '[data-tour="connect-wallet"]',
    content: (
      <div>
        <h3 className="font-bold text-lg mb-2">Connect Your Wallet</h3>
        <p>
          First, connect your wallet to interact with the Credora protocol.
          We support MetaMask and other popular wallets.
        </p>
      </div>
    ),
    placement: "bottom",
  },
  {
    target: '[data-tour="navigation"]',
    content: (
      <div>
        <h3 className="font-bold text-lg mb-2">Navigation</h3>
        <p>
          Use the navigation menu to access your Dashboard, Score details,
          and Permission management.
        </p>
      </div>
    ),
    placement: "bottom",
  },
  {
    target: '[data-tour="theme-toggle"]',
    content: (
      <div>
        <h3 className="font-bold text-lg mb-2">Theme Options</h3>
        <p>
          Switch between light and dark modes based on your preference.
        </p>
      </div>
    ),
    placement: "bottom",
  },
];

export function OnboardingTour() {
  const [run, setRun] = useState(false);
  const [mounted, setMounted] = useState(false);
  const { theme } = useTheme();

  useEffect(() => {
    setMounted(true);
    const completed = localStorage.getItem(TOUR_STORAGE_KEY);
    if (!completed) {
      // Delay tour start to let page render
      const timer = setTimeout(() => setRun(true), 1500);
      return () => clearTimeout(timer);
    }
  }, []);

  const handleCallback = (data: CallBackProps) => {
    const { status } = data;
    const finishedStatuses: string[] = [STATUS.FINISHED, STATUS.SKIPPED];
    if (finishedStatuses.includes(status)) {
      setRun(false);
      localStorage.setItem(TOUR_STORAGE_KEY, "true");
    }
  };

  if (!mounted) return null;

  return (
    <Joyride
      steps={steps}
      run={run}
      continuous
      showSkipButton
      showProgress
      callback={handleCallback}
      styles={{
        options: {
          primaryColor: "#00d4aa",
          backgroundColor: theme === "dark" ? "#1a1a2e" : "#ffffff",
          textColor: theme === "dark" ? "#f8fafc" : "#1e293b",
          arrowColor: theme === "dark" ? "#1a1a2e" : "#ffffff",
          zIndex: 10000,
        },
        tooltip: {
          borderRadius: 12,
          padding: 20,
        },
        buttonNext: {
          backgroundColor: "#00d4aa",
          color: "#0f0f23",
          borderRadius: 8,
          fontWeight: 600,
        },
        buttonBack: {
          color: theme === "dark" ? "#f8fafc" : "#1e293b",
          marginRight: 8,
        },
        buttonSkip: {
          color: theme === "dark" ? "#94a3b8" : "#64748b",
        },
      }}
      locale={{
        back: "Back",
        close: "Close",
        last: "Finish",
        next: "Next",
        skip: "Skip Tour",
      }}
    />
  );
}

export function resetOnboardingTour() {
  localStorage.removeItem(TOUR_STORAGE_KEY);
  window.location.reload();
}
