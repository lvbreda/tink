// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////

package com.google.crypto.tink.daead;

import static com.google.common.truth.Truth.assertThat;
import static java.nio.charset.StandardCharsets.UTF_8;

import com.google.crypto.tink.DeterministicAead;
import com.google.crypto.tink.KeyTemplates;
import com.google.crypto.tink.KeysetHandle;
import javax.crypto.Cipher;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;

/**
 * Unit test for {@link AeadFactory}.
 *
 * <p>The test case in this file needs {@link Registry} to not have AeadWrapper registered. That's
 * why it is in its own test file.
 */
@RunWith(JUnit4.class)
public class DeterministicAeadFactoryWithoutWrapperRegisteredTest {

  @Test
  @SuppressWarnings("deprecation") // This is a test that the deprecated function works.
  public void deprecatedFactoryGetPrimitive_whenWrapperHasNotBeenRegistered_works()
      throws Exception {
    if (Cipher.getMaxAllowedKeyLength("AES") < 256) {
      // skip all tests.
      return;
    }
    // Only register AesSivKeyManager, but not the DeterministicAeadWrapper.
    AesSivKeyManager.register(/* newKeyAllowed = */ true);
    KeysetHandle handle = KeysetHandle.generateNew(KeyTemplates.get("AES256_SIV"));

    DeterministicAead daead = DeterministicAeadFactory.getPrimitive(handle);

    byte[] plaintext = "plaintext".getBytes(UTF_8);
    byte[] associatedData = "associatedData".getBytes(UTF_8);
    byte[] ciphertext = daead.encryptDeterministically(plaintext, associatedData);
    assertThat(daead.decryptDeterministically(ciphertext, associatedData)).isEqualTo(plaintext);
  }
}
