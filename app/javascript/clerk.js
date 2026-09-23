import { Clerk } from "@clerk/clerk-js";

const clerk = new Clerk(window.CLERK_PUBLISHABLE_KEY);

const clerkDomain = atob(
  window.CLERK_PUBLISHABLE_KEY.split("_")[2]
).slice(0, -1);


/*
 * ========================================
 * Load Clerk UI
 * ========================================
 */

await new Promise((resolve, reject) => {
  const script = document.createElement("script");

  script.src = `https://${clerkDomain}/npm/@clerk/ui@1/dist/ui.browser.js`;
  script.async = true;
  script.crossOrigin = "anonymous";

  script.onload = resolve;

  script.onerror = () => {
    reject(new Error("Failed to load Clerk UI"));
  };

  document.head.appendChild(script);
});


/*
 * ========================================
 * Initialize Clerk
 * ========================================
 */

await clerk.load({
  afterSignOutUrl: "/events",
  signInForceRedirectUrl: "/events",
  signUpForceRedirectUrl: "/events",

  ui: {
    ClerkUI: window.__internal_ClerkUICtor,
  },
});


/*
 * ========================================
 * Mount Clerk Components
 * ========================================
 */

function mountClerkComponents() {
  /*
   * -------------------------------
   * User button on Events page
   * -------------------------------
   */

  const userButtonElement = document.getElementById(
    "clerk-user-button"
  );

  if (userButtonElement && clerk.isSignedIn) {
    clerk.mountUserButton(userButtonElement);
  }


  /*
   * -------------------------------
   * Sign In on Auth page
   * -------------------------------
   */

  const authElement = document.getElementById(
    "clerk-auth"
  );

  if (authElement && !clerk.isSignedIn) {
    clerk.mountSignIn(authElement, {
      forceRedirectUrl: "/events",
      fallbackRedirectUrl: "/events",

      signUpUrl: "/sign-up",
      signUpForceRedirectUrl: "/events",
      signUpFallbackRedirectUrl: "/events",

      appearance: {
        variables: {
          colorPrimary: "#8b7cff",
          colorBackground: "#151a2b",
          colorForeground: "#f5f7ff",
          colorMutedForeground: "#9da6ba",
          colorInputBackground: "#20263a",
          colorInputText: "#f5f7ff",
          colorBorder: "rgba(255, 255, 255, 0.10)",
          borderRadius: "10px",
        },

        elements: {
          card: "clerk-card",

          headerTitle: "clerk-header-title",
          headerSubtitle: "clerk-header-subtitle",

          formFieldLabel: "clerk-field-label",
          formFieldInput: "clerk-field-input",

          formButtonPrimary: "clerk-primary-button",

          socialButtonsBlockButton:
            "clerk-social-button",

          socialButtonsBlockButtonText:
            "clerk-social-button-text",

          dividerLine: "clerk-divider-line",
          dividerText: "clerk-divider-text",

          footerActionText:
            "clerk-footer-action-text",

          footerActionLink:
            "clerk-footer-action-link",
        },
      },
    });
  }


  /*
   * -------------------------------
   * Sign Up page
   * -------------------------------
   */

  const signUpElement = document.getElementById(
    "clerk-sign-up"
  );

  if (signUpElement && !clerk.isSignedIn) {
    clerk.mountSignUp(signUpElement, {
      forceRedirectUrl: "/events",
      fallbackRedirectUrl: "/events",

      signInUrl: "/auth",

      appearance: {
        variables: {
          colorPrimary: "#8b7cff",
          colorBackground: "#151a2b",
          colorForeground: "#f5f7ff",
          colorMutedForeground: "#9da6ba",
          colorInputBackground: "#20263a",
          colorInputText: "#f5f7ff",
          colorBorder: "rgba(255, 255, 255, 0.10)",
          borderRadius: "10px",
        },

        elements: {
          card: "clerk-card",

          headerTitle: "clerk-header-title",
          headerSubtitle: "clerk-header-subtitle",

          formFieldLabel: "clerk-field-label",
          formFieldInput: "clerk-field-input",

          formButtonPrimary: "clerk-primary-button",

          socialButtonsBlockButton:
            "clerk-social-button",

          socialButtonsBlockButtonText:
            "clerk-social-button-text",

          dividerLine: "clerk-divider-line",
          dividerText: "clerk-divider-text",

          footerActionText:
            "clerk-footer-action-text",

          footerActionLink:
            "clerk-footer-action-link",
        },
      },
    });
  }
}


/*
 * ========================================
 * Initial page load
 * ========================================
 */

mountClerkComponents();


/*
 * ========================================
 * Turbo navigation
 * ========================================
 */

document.addEventListener("turbo:load", function () {
  mountClerkComponents();
});