import { ref } from 'vue';
import { supabase } from '@/lib/supabase';

export interface PaymentIntegration {
  id: string;
  branch_id: string;
  provider: string;
  is_enabled: boolean;
  config: { api_key?: string; secret_key?: string; merchant_id?: string; [key: string]: any };
  webhook_url: string | null;
  last_tested_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface DeliveryIntegration {
  id: string;
  branch_id: string;
  provider: string;
  is_enabled: boolean;
  config: Record<string, any>;
  webhook_url: string | null;
  store_id: string | null;
  last_synced_at: string | null;
  created_at: string;
  updated_at: string;
}

export function useIntegrations() {
  const isFetching = ref(false);
  const error = ref<Error | null>(null);

  async function fetchAllIntegrations(branchId: string) {
    isFetching.value = true;
    error.value = null;
    try {
      return { 
        payments: [], 
        deliveries: [] 
      };
    } catch (err: any) {
      error.value = err;
      throw err;
    } finally {
      isFetching.value = false;
    }
  }

  async function savePaymentConfig(
    branchId: string,
    provider: string,
    config: { api_key: string; secret_key: string; merchant_id?: string },
    webhookUrl?: string
  ) {
    error.value = null;
    try {
      const { error: err } = await supabase
        .from('payment_integrations')
        .upsert({
          branch_id: branchId,
          provider,
          config,
          webhook_url: webhookUrl,
          updated_at: new Date().toISOString()
        }, { onConflict: 'branch_id,provider' });
      if (err) throw err;
    } catch (err: any) {
      error.value = err;
      throw err;
    }
  }

  async function saveDeliveryConfig(
    branchId: string,
    provider: string,
    config: Record<string, any>,
    webhookUrl?: string,
    storeId?: string
  ) {
    error.value = null;
    try {
      const { error: err } = await supabase
        .from('delivery_integrations')
        .upsert({
          branch_id: branchId,
          provider,
          config,
          webhook_url: webhookUrl,
          store_id: storeId,
          updated_at: new Date().toISOString()
        }, { onConflict: 'branch_id,provider' });
      if (err) throw err;
    } catch (err: any) {
      error.value = err;
      throw err;
    }
  }

  async function testPaymentConnection(branchId: string, provider: string): Promise<boolean> {
    error.value = null;
    try {
      const { data, error: err } = await supabase.functions.invoke('test-payment-provider', {
        body: { branch_id: branchId, provider }
      });
      if (!err && data?.success) {
        await supabase.from('payment_integrations')
          .update({ last_tested_at: new Date().toISOString() })
          .eq('branch_id', branchId)
          .eq('provider', provider);
        return true;
      }
      return false;
    } catch (err: any) {
      error.value = err;
      return false;
    }
  }

  async function toggleIntegration(
    branchId: string,
    provider: string,
    type: 'payment' | 'delivery',
    isEnabled: boolean
  ) {
    error.value = null;
    try {
      const table = type === 'payment' ? 'payment_integrations' : 'delivery_integrations';
      const { error: err } = await supabase
        .from(table)
        .update({ is_enabled: isEnabled, updated_at: new Date().toISOString() })
        .eq('branch_id', branchId)
        .eq('provider', provider);
      if (err) throw err;
    } catch (err: any) {
      error.value = err;
      throw err;
    }
  }

  return {
    isFetching,
    error,
    fetchAllIntegrations,
    savePaymentConfig,
    saveDeliveryConfig,
    testPaymentConnection,
    toggleIntegration
  };
}
