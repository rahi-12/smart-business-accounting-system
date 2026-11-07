const test = require("node:test");
const assert = require("node:assert/strict");

const authService = require("../src/services/authService");
const { getProfile } = require("../src/controllers/authController");

function responseRecorder() {
    return {
        statusCode: undefined,
        body: undefined,
        status(statusCode) {
            this.statusCode = statusCode;
            return this;
        },
        json(body) {
            this.body = body;
            return this;
        },
    };
}

test("returns 404 only when the profile service reports PROFILE_NOT_FOUND", async () => {
    const originalGetUserProfile = authService.getUserProfile;
    authService.getUserProfile = async () => {
        const error = new Error("User profile not found.");
        error.code = "PROFILE_NOT_FOUND";
        throw error;
    };

    try {
        const res = responseRecorder();
        await getProfile({ user: { uid: "firebase-uid" } }, res);

        assert.equal(res.statusCode, 404);
        assert.deepEqual(res.body, {
            success: false,
            code: "PROFILE_NOT_FOUND",
            message: "Profile not found.",
        });
    } finally {
        authService.getUserProfile = originalGetUserProfile;
    }
});

test("returns 500 for unexpected profile repository errors", async () => {
    const originalGetUserProfile = authService.getUserProfile;
    const originalConsoleError = console.error;
    authService.getUserProfile = async () => {
        throw new Error("Database unavailable.");
    };
    console.error = () => {};

    try {
        const res = responseRecorder();
        await getProfile({ user: { uid: "firebase-uid" } }, res);

        assert.equal(res.statusCode, 500);
        assert.deepEqual(res.body, {
            success: false,
            code: "PROFILE_LOOKUP_FAILED",
            message: "Unable to load user profile.",
        });
    } finally {
        authService.getUserProfile = originalGetUserProfile;
        console.error = originalConsoleError;
    }
});
