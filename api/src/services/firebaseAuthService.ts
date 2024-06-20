import { CreateRequest } from "firebase-admin/auth";
import { db, firebaseAdminApp } from "../firebaseConfig";
import { getAuth } from "firebase-admin/auth";
import { fetchSpotifyProfile } from "./spotifyAPIService";

export async function findOrCreateCustomClientToken(
  spotifyAccessToken: string,
  spotifyRefreshToken: string,
  expiresAt: string
) {
  const userProfile = await fetchSpotifyProfile(spotifyAccessToken);

  const uid = `spotify:${userProfile.id}`;
  const saveSpotifyAuthTask = saveSpotifyAuthInfo(
    uid,
    spotifyAccessToken,
    spotifyRefreshToken,
    new Date(expiresAt)
  );
  const firebaseAdmin = await firebaseAdminApp;
  // Create or update the user account.
  const userCreationTask = firebaseAdmin
    .auth()
    .updateUser(uid, {
      displayName: userProfile.display_name,
      photoURL:
        userProfile.images && userProfile.images.length > 0
          ? userProfile.images[0].url
          : null,
      email: userProfile.email,
      emailVerified: true,
    })
    .catch((error) => {
      console.log("error updating user: ", error);
      // If user does not exists we create it.
      if (error.code === "auth/user-not-found") {
        const userProps: CreateRequest = {
          uid: uid,
          displayName: userProfile.display_name,
          email: userProfile.email,
          emailVerified: true,
        };

        if (
          userProfile.images &&
          userProfile.images?.length > 0 &&
          userProfile.images[0].url
        ) {
          userProps.photoURL = userProfile.images[0].url;
        }

        return firebaseAdmin.auth().createUser(userProps);
      }
      throw error;
    });
  await Promise.all([saveSpotifyAuthTask, userCreationTask]);
  return getAuth().createCustomToken(uid);
}

export async function storeAuth(
  accessToken: string,
  refreshToken: string,
  expiresIn: number,
  spotifyAuthFirestoreId: string
) {
  const currentDate = new Date();
  const expiresAt = new Date(currentDate.getTime() + expiresIn * 1000);

  const firestoreAuthRef = db
    .collection("spotifyAuth")
    .doc(spotifyAuthFirestoreId);
  const updatedDocInfo: {
    accessToken: string;
    expiresAt: Date;
    refreshToken?: string | null;
  } = {
    accessToken,
    expiresAt,
  };
  // refreshToken may/may not be updated... so only overwrite if spotify returns it
  if (refreshToken) {
    updatedDocInfo.refreshToken = refreshToken;
  }

  await firestoreAuthRef.update(updatedDocInfo);
}

export async function verifyTokenAndGetUid(tokenId: string) {
  const firebaseAdmin = await firebaseAdminApp;
  const res = await firebaseAdmin.auth().verifyIdToken(tokenId);
  return res.uid;
}

// this function is mostly dupe with storeAuth? but sets instead of update.
// let's not change in this refactor. but consider at some point
async function saveSpotifyAuthInfo(uid, accessToken, refreshToken, expiresAt) {
  const firestoreAuthRef = db.collection("spotifyAuth").doc(uid);
  const docInfo: {
    accessToken: string;
    expiresAt: Date;
    refreshToken?: string | null;
  } = {
    accessToken,
    expiresAt,
  };
  // refreshToken may/may not be updated... so only overwrite if spotify returns it
  if (refreshToken) {
    docInfo.refreshToken = refreshToken;
  }
  await firestoreAuthRef.set(docInfo);
}
